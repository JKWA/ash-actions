defmodule MissionControl.Superhero.Calculations.Healthy do
  use Ash.Resource.Calculation

  @impl true
  def init(opts) do
    case Keyword.fetch(opts, :threshold) do
      {:ok, threshold} when is_integer(threshold) and threshold > 0 and threshold <= 100 ->
        {:ok, opts}

      {:ok, threshold} when is_integer(threshold) ->
        {:error, "threshold must be between 1 and 100, got: #{threshold}"}

      {:ok, _} ->
        {:error, "threshold must be an integer"}

      :error ->
        {:error, "threshold option is required"}
    end
  end

  @impl true
  def describe(opts) do
    threshold = Keyword.fetch!(opts, :threshold)
    "Whether the superhero is in good health (>#{threshold} HP)"
  end

  @impl true
  def expression(opts, _context) do
    threshold = Keyword.fetch!(opts, :threshold)
    expr(health > ^threshold)
  end

  @impl true
  def calculate(records, opts, _context) do
    threshold = Keyword.fetch!(opts, :threshold)

    results =
      Enum.map(records, fn record ->
        record.health > threshold
      end)

    {:ok, results}
  end
end
