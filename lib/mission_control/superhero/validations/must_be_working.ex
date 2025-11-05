defmodule MissionControl.Superhero.Validations.MustBeWorking do
  use Ash.Resource.Validation
  alias MissionControl.Superhero

  @impl true
  def validate(changeset, _opts, _context) do
    superhero = changeset.data

    if Superhero.working?(superhero) do
      :ok
    else
      {:error,
       field: :status,
       message: "#{superhero.alias} must be working (current status: #{superhero.status})"}
    end
  end
end
