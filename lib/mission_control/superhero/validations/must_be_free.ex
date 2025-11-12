defmodule MissionControl.Superhero.Validations.MustBeFree do
  use Ash.Resource.Validation
  alias MissionControl.Superhero

  @impl true
  def validate(changeset, _opts, _context) do
    superhero = changeset.data

    if Superhero.free?(superhero) do
      :ok
    else
      {:error,
       field: :status,
       message: "#{superhero.alias} must be free (current status: #{superhero.status})"}
    end
  end
end
