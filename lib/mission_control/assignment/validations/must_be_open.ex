defmodule MissionControl.Assignment.Validations.MustBeOpen do
  use Ash.Resource.Validation
  alias Ash.Error.Changes.InvalidAttribute

  @impl true
  def validate(changeset, _opts, _context) do
    assignment = changeset.data

    if assignment.status == :open do
      :ok
    else
      {:error,
       InvalidAttribute.exception(
         field: :status,
         message: "Assignment must be open to dispatch",
         value: assignment.status
       )}
    end
  end
end
