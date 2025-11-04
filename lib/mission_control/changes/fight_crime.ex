defmodule MissionControl.Changes.FightCrime do
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    hero = changeset.data
    difficulty = Ash.Changeset.get_argument(changeset, :difficulty) || 1

    win_chance = max(0, min(100, hero.health - difficulty * 10))
    won? = :rand.uniform(100) <= win_chance

    if won? do
      changeset
      |> inc(:fights_won, 1)
      |> set_health(hero.health - difficulty * 5)
    else
      changeset
      |> inc(:fights_lost, 1)
      |> set_health(hero.health - difficulty * 10)
      |> Ash.Changeset.force_change_attribute(:is_patrolling, false)
    end
  end

  defp inc(changeset, field, by) do
    current = Map.get(changeset.data, field) || 0
    Ash.Changeset.change_attribute(changeset, field, current + by)
  end

  defp set_health(changeset, new_health) do
    bounded_health = max(0, min(100, new_health))
    Ash.Changeset.change_attribute(changeset, :health, bounded_health)
  end
end
