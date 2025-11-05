defmodule MissionControl.Superhero.Validations.MustBeOffDuty do
  use Ash.Resource.Validation
  alias MissionControl.Superhero

  @impl true
  def validate(changeset, _opts, _context) do
    superhero = changeset.data

    if Superhero.off_duty?(superhero) do
      :ok
    else
      {:error,
       field: :status,
       message: "#{superhero.alias} must be off duty (current status: #{superhero.status})"}
    end
  end
end
