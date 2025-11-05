defmodule MissionControl.Superhero.Validations.MustBeOnDuty do
  use Ash.Resource.Validation
  alias MissionControl.Superhero

  @impl true
  def validate(changeset, _opts, _context) do
    superhero = changeset.data

    if Superhero.on_duty?(superhero) do
      :ok
    else
      {:error,
       field: :status,
       message:
         "#{superhero.alias} must be on duty to dispatch (current status: #{superhero.status})"}
    end
  end
end
