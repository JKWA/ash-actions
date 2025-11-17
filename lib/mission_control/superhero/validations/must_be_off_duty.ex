defmodule MissionControl.Superhero.Validations.MustBeOffDuty do
  use Ash.Resource.Validation
  alias MissionControl.Superhero
  alias Ash.Error.Changes.InvalidAttribute

  @impl true
  def validate(changeset, _opts, _context) do
    superhero = changeset.data

    if Superhero.off_duty?(superhero) do
      :ok
    else
      {:error,
       InvalidAttribute.exception(
         field: :status,
         message: "#{superhero.alias} must be off duty",
         value: superhero.status
       )}
    end
  end
end
