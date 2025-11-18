defmodule MissionControl.Assignment.Validations.CheckBeforeDelete do
  use Ash.Resource.Validation
  import Funx.Foldable
  alias Funx.Monad.Effect
  alias MissionControl.Validations

  @impl true
  def validate(changeset, _opts, _context) do

    validators = [
      &Validations.mission_clearance/1,
      &Validations.equipment_return/1,
      &Validations.citizen_safety/1,
      &Validations.backup_coverage/1,
      &Validations.insurance_claims/1
    ]

    assignment = Ash.load!(changeset.data, :superhero)

    Effect.validate(assignment.superhero, validators)
    |> Effect.run()
    |> map_result_to_ash()
  end

  defp map_result_to_ash(value) do
    fold_l(
      value,
      fn _val -> :ok end,
      fn errors -> {
        :error,
        field: :base,
        message: "#{Enum.join(errors, ", ")}"
      } end
    )
  end
end
