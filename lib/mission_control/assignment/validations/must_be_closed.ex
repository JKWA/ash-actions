defmodule MissionControl.Assignment.Validations.MustBeClosed do
  use Ash.Resource.Validation
  alias Ash.Error.Changes.InvalidAttribute

  @impl true
  def validate(changeset, _opts, _context) do
    assignment = changeset.data

    if assignment.status == :closed do
      :ok
    else
      {:error,
       InvalidAttribute.exception(
         field: :status,
         message: "Assignment must be closed to reopen",
         value: assignment.status
       )}
    end
  end
end
