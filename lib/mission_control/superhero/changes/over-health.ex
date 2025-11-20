defmodule MissionControl.Changes.Superhero.OverHealth do
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    # Health has constraints: min: 0, max: 100
    # But this bypasses those constraints entirely:
    %{changeset | attributes: Map.put(changeset.attributes, :health, 999)}
  end
end
