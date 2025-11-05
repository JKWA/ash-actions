defmodule MissionControl.Assignment.Validations.MustBeClosed do
  use Ash.Resource.Validation

  @impl true
  def validate(changeset, _opts, _context) do
    assignment = changeset.data

    if assignment.status == :closed do
      :ok
    else
      {:error,
       field: :status,
       message: "Assignment must be closed to reopen (current status: #{assignment.status})"}
    end
  end
end
