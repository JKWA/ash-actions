defmodule MissionControl.Superhero.Calculations.WinRate do
  use Ash.Resource.Calculation
  alias MissionControl.Assignment

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def describe(_opts) do
    "Win rate calculated from assignment results"
  end

  @impl true
  def load(_query, _opts, _context) do
    [assignments: [:status, :result]]
  end

  @impl true
  def calculate(records, _opts, _context) do
    results =
      Enum.map(records, fn record ->
        closed_assignments =
          record.assignments
          |> Enum.filter(&Assignment.closed?/1)

        total_fights = length(closed_assignments)

        if total_fights > 0 do
          wins = Enum.count(closed_assignments, &Assignment.won?/1)
          wins / total_fights
        else
          0.0
        end
      end)

    {:ok, results}
  end
end
