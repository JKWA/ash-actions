defmodule MissionControl.Changes.BeginMission do
  use Ash.Resource.Change
  import Funx.Monad
  alias Funx.Monad.{Effect, Either}

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, {assignment, superhero} ->
      Effect.sequence_a([
        update_superhero(superhero),
        update_assignment(assignment)
      ])
      |> Effect.run()
      |> map(fn [_updated_superhero, updated_assignment] ->
        # Return only the assignment - action is closed under its resource context
        updated_assignment
      end)
      |> Either.to_result()
    end)
  end

  defp update_superhero(superhero) do
    superhero
    |> Ash.Changeset.for_action(:update, %{status: :on_duty})
    |> Ash.update()
    |> Effect.from_result()
  end

  defp update_assignment(assignment) do
    assignment
    |> Ash.Changeset.for_action(:update, %{status: :fighting})
    |> Ash.update()
    |> Effect.from_result()
  end
end
