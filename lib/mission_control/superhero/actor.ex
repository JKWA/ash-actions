defmodule MissionControl.Superhero.Actor do
  use GenServer
  require Logger

  def start_link(superhero_id) do
    GenServer.start_link(__MODULE__, superhero_id, name: via_tuple(superhero_id))
  end

  def get_state(superhero_id) do
    GenServer.call(via_tuple(superhero_id), :get_state)
  end

  def alive?(superhero_id) do
    case Registry.lookup(MissionControl.SuperheroRegistry, superhero_id) do
      [{_pid, _}] -> true
      [] -> false
    end
  end

  @impl true
  def init(superhero_id) do
    case MissionControl.get_superhero(superhero_id) do
      {:ok, superhero} ->
        Logger.info(
          "Superhero.Actor started for #{superhero.name} (#{superhero.alias}) - ID: #{superhero.id}"
        )

        timer_ref =
          if superhero.status in [:dispatched, :off_duty], do: schedule_health_report(), else: nil

        {:ok, %{superhero: superhero, health_timer: timer_ref}}

      {:error, reason} ->
        Logger.error("Failed to start Superhero.Actor for ID #{superhero_id}: #{inspect(reason)}")
        {:stop, {:superhero_not_found, reason}}
    end
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:report_health, state) do
    cond do
      state.superhero.status == :dispatched ->
        old_health = state.superhero.health
        health_delta = Enum.random(-10..3)

        new_health =
          (old_health + health_delta)
          |> max(0)
          |> min(100)

        if new_health == 0 do
          Logger.warning("#{state.superhero.name} health depleted! Actor terminating...")

          case MissionControl.update_health_superhero(state.superhero, %{health: 0}) do
            {:ok, _updated_superhero} ->
              {:stop, :health_depleted, state}

            {:error, _reason} ->
              {:stop, :health_depleted, state}
          end
        else
          case MissionControl.update_health_superhero(state.superhero, %{health: new_health}) do
            {:ok, updated_superhero} ->
              timer_ref = schedule_health_report()
              {:noreply, %{state | superhero: updated_superhero, health_timer: timer_ref}}

            {:error, _reason} ->
              timer_ref = schedule_health_report()
              {:noreply, %{state | health_timer: timer_ref}}
          end
        end

      state.superhero.status == :recovery ->
        old_health = state.superhero.health

        if old_health >= 100 do
          Logger.info("#{state.superhero.name} has fully recovered! Moving to off duty.")

          case MissionControl.off_duty_superhero(state.superhero) do
            {:ok, updated_superhero} ->
              if state.health_timer, do: Process.cancel_timer(state.health_timer)
              {:noreply, %{state | superhero: updated_superhero, health_timer: nil}}

            {:error, reason} ->
              Logger.error("Failed to move #{state.superhero.name} to off duty: #{inspect(reason)}")
              timer_ref = schedule_health_report()
              {:noreply, %{state | health_timer: timer_ref}}
          end
        else
          health_delta = Enum.random(1..3)

          new_health =
            (old_health + health_delta)
            |> min(100)

          case MissionControl.update_health_superhero(state.superhero, %{health: new_health}) do
            {:ok, updated_superhero} ->
              timer_ref = schedule_health_report()
              {:noreply, %{state | superhero: updated_superhero, health_timer: timer_ref}}

            {:error, _reason} ->
              timer_ref = schedule_health_report()
              {:noreply, %{state | health_timer: timer_ref}}
          end
        end

      true ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(:dispatched, state) do
    Logger.info("#{state.superhero.name} has been dispatched! Starting health monitoring...")

    updated_superhero = %{state.superhero | status: :dispatched}

    if state.health_timer, do: Process.cancel_timer(state.health_timer)
    timer_ref = schedule_health_report()

    case MissionControl.Assignment
         |> Ash.Query.for_read(:by_superhero, %{superhero_id: state.superhero.id})
         |> Ash.read() do
      {:ok, [assignment | _]} ->
        fight_delay = Enum.random(2_000..4_000)
        Process.send_after(self(), {:start_fighting, assignment.id}, fight_delay)
        Logger.info("#{state.superhero.name} will engage in combat in #{fight_delay}ms")

      {:ok, []} ->
        Logger.warning("#{state.superhero.name} dispatched but no assignment found")

      {:error, reason} ->
        Logger.error("Failed to find assignment: #{inspect(reason)}")
    end

    {:noreply, %{state | superhero: updated_superhero, health_timer: timer_ref}}
  end

  @impl true
  def handle_info(:went_on_duty, state) do
    Logger.info("#{state.superhero.name} is now on duty. Stopping health monitoring.")

    updated_superhero = %{state.superhero | status: :on_duty}

    if state.health_timer, do: Process.cancel_timer(state.health_timer)

    {:noreply, %{state | superhero: updated_superhero, health_timer: nil}}
  end

  @impl true
  def handle_info(:went_off_duty, state) do
    Logger.info("#{state.superhero.name} has gone off duty.")

    updated_superhero = %{state.superhero | status: :off_duty}

    if state.health_timer, do: Process.cancel_timer(state.health_timer)
    timer_ref = schedule_health_report()

    {:noreply, %{state | superhero: updated_superhero, health_timer: timer_ref}}
  end

  @impl true
  def handle_info(:went_to_recovery, state) do
    Logger.info("#{state.superhero.name} has gone to recovery. Starting health regeneration.")

    updated_superhero = %{state.superhero | status: :recovery}

    if state.health_timer, do: Process.cancel_timer(state.health_timer)
    timer_ref = schedule_health_report()

    {:noreply, %{state | superhero: updated_superhero, health_timer: timer_ref}}
  end

  @impl true
  def handle_info({:start_fighting, assignment_id}, state) do
    Logger.info("#{state.superhero.name} engages in combat!")

    case Ash.get(MissionControl.Assignment, assignment_id) do
      {:ok, assignment} ->
        case MissionControl.start_fighting_assignment(assignment) do
          {:ok, _updated_assignment} ->
            finish_delay = Enum.random(6_000..10_000)
            Process.send_after(self(), {:finish_fight, assignment_id}, finish_delay)
            Logger.info("#{state.superhero.name} will finish combat in #{finish_delay}ms")

          {:error, reason} ->
            Logger.error("Failed to start fighting: #{inspect(reason)}")
        end

      {:error, reason} ->
        Logger.error("Failed to get assignment: #{inspect(reason)}")
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:finish_fight, assignment_id}, state) do
    case Ash.get(MissionControl.Assignment, assignment_id) do
      {:ok, assignment} ->
        # Randomly determine outcome
        result = if Enum.random(1..100) > 50, do: :won, else: :lost

        Logger.info(
          "#{state.superhero.name} #{if result == :won, do: "won", else: "lost"} the fight!"
        )

        case MissionControl.update_result_assignment(assignment, %{result: result}) do
          {:ok, _updated_assignment} ->
            Logger.info("Assignment result updated to #{result}")

          {:error, reason} ->
            Logger.error("Failed to update result: #{inspect(reason)}")
        end

      {:error, reason} ->
        Logger.error("Failed to get assignment: #{inspect(reason)}")
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:terminate, state) do
    Logger.warning("#{state.superhero.name} actor received termination command")
    {:stop, :terminated_by_user, state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(reason, state) do
    case reason do
      :health_depleted ->
        Logger.error("#{state.superhero.name} has been defeated (health depleted)")

        case MissionControl.Assignment
             |> Ash.Query.for_read(:by_superhero, %{superhero_id: state.superhero.id})
             |> Ash.read() do
          {:ok, [assignment | _]} ->
            case MissionControl.update_result_assignment(assignment, %{result: :lost}) do
              {:ok, _} ->
                Logger.info("Marked assignment as lost due to health depletion")

              {:error, reason} ->
                Logger.error("Failed to mark assignment as lost: #{inspect(reason)}")
            end

          _ ->
            Logger.debug("No active assignment found for defeated superhero")
        end

        case MissionControl.delete_superhero(state.superhero) do
          :ok ->
            Logger.info("Cleaned up defeated superhero #{state.superhero.name} from database")

          {:error, reason} ->
            Logger.error("Failed to cleanup defeated superhero: #{inspect(reason)}")
        end

      :terminated_by_user ->
        Logger.warning("#{state.superhero.name} actor terminated by user command")

      :normal ->
        Logger.info("#{state.superhero.name} actor stopped normally")

      reason ->
        Logger.error("#{state.superhero.name} actor crashed: #{inspect(reason)}")
    end

    :ok
  end

  def via_tuple(superhero_id) do
    {:via, Registry, {MissionControl.SuperheroRegistry, superhero_id}}
  end

  defp schedule_health_report do
    interval = Enum.random(500..1_500)
    Process.send_after(self(), :report_health, interval)
  end
end
