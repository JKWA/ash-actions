defmodule MissionControl.Superhero.Validations.MustBeWorking do
  use Ash.Resource.Validation
  alias MissionControl.Superhero
  alias Ash.Error.Changes.InvalidAttribute

  @impl true
  def validate(changeset, _opts, _context) do
    superhero = changeset.data

    if Superhero.working?(superhero) do
      :ok
    else
      {:error,
       InvalidAttribute.exception(
         field: :status,
         message: "#{superhero.alias} must be working",
         value: superhero.status
       )}
    end
  end
end
