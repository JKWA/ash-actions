defmodule MissionControl.Validations do
  alias Funx.Monad.{Effect, Either}
  require Logger

  def mission_clearance(superhero) do
    Effect.lift_either(fn ->
      slow_validate(superhero, :mission_clearance)
    end)
  end

  def equipment_return(superhero) do
    Effect.lift_either(fn -> slow_validate(superhero, :equipment_return) end)
  end

  def citizen_safety(superhero) do
    Effect.lift_either(fn -> slow_validate(superhero, :citizen_safety) end)
  end

  def backup_coverage(superhero) do
    Effect.lift_either(fn -> slow_validate(superhero, :backup_coverage) end)
  end

  def insurance_claims(superhero) do
    Effect.lift_either(fn -> slow_validate(superhero, :insurance_claims) end)
  end

  defp slow_validate(superhero, check_name) do
    Either.lift_predicate(
      check_name,
      &slow_check?/1,
      fn _value -> [format_error(superhero.alias, check_name)] end
    )
  end

  # Simulated expensive check (50-250ms) - randomly fails 1 out of 5 times
  defp slow_check?(_value) do
    delay_ms = Enum.random(1..5) * 50
    :timer.sleep(delay_ms)
    Logger.info("Completed slow check for #{delay_ms}ms")
    Enum.random(1..5) != 1
  end

  defp format_error(alias, :mission_clearance), do: "#{alias} failed to clear mission"
  defp format_error(alias, :equipment_return), do: "#{alias} failed to return equipment"
  defp format_error(alias, :citizen_safety), do: "#{alias} failed citizen safety check"
  defp format_error(alias, :backup_coverage), do: "#{alias} failed backup coverage verification"
  defp format_error(alias, :insurance_claims), do: "#{alias} has pending insurance claims"
end
