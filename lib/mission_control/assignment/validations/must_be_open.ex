defmodule MissionControl.Assignment.Validations.MustBeOpen do
  use Ash.Resource.Validation

  @impl true
  def validate(changeset, _opts, _context) do
    assignment = changeset.data

    if assignment.status == :open do
      :ok
    else
      {:error,
       field: :status,
       message: "Assignment must be open to dispatch (current status: #{assignment.status})"}
    end
  end
end
