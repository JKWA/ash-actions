defmodule MissionControl.Assignment.Calculations.MaybeSuperhero do
  use Ash.Resource.Calculation
  alias Funx.Monad.Maybe

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def describe(_opts) do
    "Returns the superhero wrapped in a Maybe monad (Just or Nothing)"
  end

  @impl true
  def load(_query, _opts, _context) do
    [superhero: [:name, :alias, :status, :health]]
  end

  @impl true
  def calculate(records, _opts, _context) do
    results =
      Enum.map(records, fn record ->
        Maybe.from_nil(record.superhero)
      end)

    {:ok, results}
  end
end
