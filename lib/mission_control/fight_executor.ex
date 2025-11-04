defmodule MissionControl.FightExecutor do
  @moduledoc """
  Handles asynchronous execution of crime-fighting assignments.
  """

  def execute_async(assignment_id) do
    Task.start(fn ->
      # Wait for the fight to happen (5 seconds for now)
      Process.sleep(5000)

      # Load the assignment
      assignment = Ash.get!(MissionControl.Assignment, assignment_id)

      # Load the superhero
      superhero = Ash.get!(MissionControl.Superhero, assignment.superhero_id)

      # Execute the fight logic
      {won?, health_cost} = execute_fight(superhero, assignment.difficulty)

      # Update the superhero
      update_superhero(superhero, won?, health_cost)

      # Update the assignment with results
      update_assignment(assignment, won?, health_cost)
    end)
  end

  defp execute_fight(superhero, difficulty) do
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
          is_patrolling: false
        })
      else
        superhero
        |> Ash.Changeset.for_action(:update, %{
          fights_lost: superhero.fights_lost + 1,
          health: max(0, min(100, superhero.health - health_cost)),
          is_patrolling: false
        })
      end

    Ash.update!(changeset)
  end

  defp update_assignment(assignment, won?, health_cost) do
    result = if won?, do: "won", else: "lost"

    assignment
    |> Ash.Changeset.for_action(:update, %{
      status: "completed",
      result: result,
      health_cost: health_cost
    })
    |> Ash.update!()
  end
end
