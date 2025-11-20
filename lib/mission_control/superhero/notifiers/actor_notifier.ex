defmodule MissionControl.Superhero.Notifiers.ActorNotifier do
  @moduledoc """
  Notifier that informs Superhero.Actors after successful actions.
  If the actor is dead, deletes the superhero record.

  Philosophy: The actor IS the superhero. The DB save is optimistic,
  but if the actor is dead when we try to notify it, we clean up.
  """
  use Ash.Notifier
  require Logger

  @impl true
  def notify(%Ash.Notifier.Notification{resource: resource, action: action, data: superhero})
      when resource == MissionControl.Superhero do
    # Only notify for status-changing actions
    if action.name in [:dispatch, :on_duty, :off_duty] do
      message = action_to_message(action.name)

      case notify_actor(superhero.id, message) do
        :ok ->
          :ok

        {:error, :actor_dead} ->
          Logger.warning(
            "Actor dead after #{action.name}, cleaning up superhero #{superhero.name}"
          )

          cleanup_dead_superhero(superhero)
      end
    end

    :ok
  end

  def notify(_), do: :ok

  defp action_to_message(:dispatch), do: :dispatched
  defp action_to_message(:on_duty), do: :went_on_duty
  defp action_to_message(:off_duty), do: :went_off_duty
  defp action_to_message(:recovery), do: :went_to_recovery

  defp notify_actor(superhero_id, message) do
    case Registry.lookup(MissionControl.SuperheroRegistry, superhero_id) do
      [{pid, _}] ->
        send(pid, message)
        :ok

      [] ->
        {:error, :actor_dead}
    end
  end

  defp cleanup_dead_superhero(superhero) do
    case MissionControl.delete_superhero(superhero) do
      :ok ->
        Logger.info("Cleaned up dead superhero #{superhero.name} from database")

      {:error, reason} ->
        Logger.error("Failed to cleanup dead superhero: #{inspect(reason)}")
    end
  end
end
