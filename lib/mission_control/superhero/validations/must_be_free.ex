defmodule MissionControl.Superhero.Validations.MustBeFree do
  use Ash.Resource.Validation
  alias MissionControl.Superhero
  alias Ash.Error.Changes.InvalidAttribute

  @impl true
  def validate(changeset, _opts, _context) do
    superhero = changeset.data

    if not Superhero.working?(superhero) do
      :ok
    else
      {:error,
       InvalidAttribute.exception(
         field: :status,
         message: "#{superhero.alias} must be free",
         value: superhero.status
       )}
    end
  end
end
