defmodule MissionControl.Assignment.Changes.EnforceSingleAssignment do
  use Ash.Resource.Change
  import Funx.Monad
  import Funx.Monad.Either
  import Funx.Foldable
  import Funx.Utils

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn changeset, assignment ->
      load_superhero(assignment)
      |> bind(curry_r(&check_no_other_assignments/2).(assignment))
      |> map_left(curry_r(&revert_assignment/3).(changeset).(assignment))
      |> map(fn _superhero -> assignment end)
      |> to_result()
    end)
  end

  defp load_superhero(assignment) do
    MissionControl.get_superhero(assignment.superhero_id)
    |> from_result()
  end

  defp check_no_other_assignments(superhero, assignment) do
    MissionControl.list_assignments_by_superhero(superhero.id)
    |> from_result()
    |> map(curry_r(&filter_other_assignments/2).(assignment))
    |> bind(curry_r(&validate_no_conflicts/2).(superhero))
  end

  defp filter_other_assignments(assignments, assignment) do
    Enum.reject(assignments, &(&1.id == assignment.id))
  end

  defp validate_no_conflicts(assignments, superhero) do
    lift_predicate(
      superhero,
      fn _ -> Enum.empty?(assignments) end,
      fn s ->
        Ash.Error.Changes.InvalidChanges.exception(
          fields: [:superhero_id],
          message: "#{s.alias} already has an active assignment"
        )
      end
    )
  end

  defp delete_assignment(assignment) do
    Ash.destroy(assignment)
    |> normalize_destroy_result()
    |> from_result()
  end

  defp normalize_destroy_result(:ok), do: {:ok, nil}
  defp normalize_destroy_result(result), do: result

  defp close_assignment(assignment) do
    assignment
    |> Ash.Changeset.for_update(:close)
    |> Ash.update()
    |> from_result()
  end

  defp aggregate_errors(error1, error2) do
    Ash.Error.to_error_class([error1, error2])
  end

  defp revert_assignment(error, assignment, changeset) do
    rollback_operation =
      case changeset.action.name do
        :create -> &delete_assignment/1
        :reopen -> &close_assignment/1
        _ -> &delete_assignment/1
      end

    rollback_operation.(assignment)
    |> fold_l(
      fn rollback_error -> aggregate_errors(error, rollback_error) end,
      fn _ -> error end
    )
  end
end
