defmodule MissionControl.Changes.StartAssignment do
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, assignment ->
      # Set superhero to patrolling
      superhero = Ash.get!(MissionControl.Superhero, assignment.superhero_id)

      superhero
      |> Ash.Changeset.for_action(:update, %{is_patrolling: true})
      |> Ash.update!()

      # Start async fight execution
      MissionControl.FightExecutor.execute_async(assignment.id)

      {:ok, assignment}
    end)
  end
end
