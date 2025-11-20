defmodule MissionControl.Superhero.Calculations.Free do
  use Ash.Resource.Calculation

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def describe(_opts) do
    "Whether the superhero is free to take on a new assignment"
  end

  @impl true
  def expression(_opts, _context) do
    expr(status == :off_duty)
  end

  @impl true
  def calculate(records, _opts, _context) do
    results =
      Enum.map(records, fn record ->
        record.status == :off_duty
      end)

    {:ok, results}
  end
end
