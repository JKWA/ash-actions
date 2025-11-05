defmodule MissionControl.FightExecutor do
  @moduledoc """
  Handles asynchronous execution of crime-fighting assignments.
  """

  import Funx.Monad
  alias Funx.Monad.Effect

  def execute_async(assignment_id) do
    load_assignment(assignment_id)
    |> bind(fn assignment ->
      load_superhero(assignment.superhero_id)
      |> map(fn superhero -> {assignment, superhero} end)
    end)
    |> bind(fn {assignment, superhero} ->
      {won?, health_cost} = execute_fight(superhero, assignment.difficulty)

      [
        update_superhero(superhero, won?, health_cost),
        update_assignment(assignment, won?, health_cost)
      ]
      |> Effect.sequence_a()
    end)
    |> Effect.run()
  end

  defp execute_fight(superhero, difficulty) do
    Process.sleep(5000)
    win_chance = max(0, min(100, superhero.health - difficulty * 10))
    won? = :rand.uniform(100) <= win_chance

    health_cost =
      if won? do
        difficulty * 5
      else
        difficulty * 10
      end

    {won?, health_cost}
  end

  defp update_superhero(superhero, won?, health_cost) do
    changeset =
      if won? do
        superhero
        |> Ash.Changeset.for_action(:update, %{
          fights_won: superhero.fights_won + 1,
          health: max(0, min(100, superhero.health - health_cost)),
          status: :off_duty
        })
      else
        superhero
        |> Ash.Changeset.for_action(:update, %{
          fights_lost: superhero.fights_lost + 1,
          health: max(0, min(100, superhero.health - health_cost)),
          status: :off_duty
        })
      end

    Ash.update(changeset)
    |> Effect.from_result()
  end

  defp update_assignment(assignment, won?, health_cost) do
    result = if won?, do: "won", else: "lost"

    assignment
    |> Ash.Changeset.for_action(:update, %{
      status: "completed",
      result: result,
      health_cost: health_cost
    })
    |> Ash.update()
    |> Effect.from_result()
  end

  defp load_assignment(assignment_id) do
    Ash.get(MissionControl.Assignment, assignment_id)
    |> Effect.from_result()
  end

  defp load_superhero(superhero_id) do
    Ash.get(MissionControl.Superhero, superhero_id)
    |> Effect.from_result()
  end
end
