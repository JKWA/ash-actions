defmodule MissionControl.Assignment.Calculations.Closed do
  use Ash.Resource.Calculation
  alias MissionControl.Assignment

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def describe(opts) do
    "Whether the assignment is closed"
  end

  @impl true
  def expression(_opts, _context) do
    expr(status == :closed)
  end

  @impl true
  def calculate(records, _opts, _context) do
    results =
      Enum.map(records, fn assignment ->
        Assignment.closed?(assignment)
      end)

    {:ok, results}
  end
end
