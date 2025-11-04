defmodule MissionControl.Superhero do
  use Ash.Resource,
    otp_app: :mission_control,
    domain: MissionControl,
    data_layer: Ash.DataLayer.Ets

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name, :alias, :is_patrolling, :fights_won, :fights_lost, :health]
    end

    update :update do
      primary? true
      accept [:name, :alias, :is_patrolling, :fights_won, :fights_lost, :health]
    end

    update :fight_crime do
      require_atomic? false
      argument :difficulty, :integer, allow_nil?: false, default: 1
      change MissionControl.Changes.FightCrime
    end
  end

  attributes do
    attribute :id, :uuid do
      description "Unique identifier for the superhero"
      allow_nil? false
      primary_key? true
      default &Ash.UUID.generate/0
    end

    attribute :name, :string do
      description "Superhero name (e.g., 'Super Batman')"
      allow_nil? false
      public? true
      constraints min_length: 3, max_length: 100
    end

    attribute :alias, :string do
      description "Superhero alias (e.g., 'The Dark Knight')"
      allow_nil? true
      public? true
      constraints min_length: 1, max_length: 100
    end

    attribute :is_patrolling, :boolean do
      description "Whether the superhero is currently patrolling"
      allow_nil? false
      public? true
      default false
    end

    attribute :fights_won, :integer do
      description "Number of fights won"
      allow_nil? false
      public? true
      constraints min: 0
      default 0
    end

    attribute :fights_lost, :integer do
      description "Number of fights lost"
      allow_nil? false
      public? true
      constraints min: 0
      default 0
    end

    attribute :health, :integer do
      description "Current health points (0-100)"
      allow_nil? false
      public? true
      constraints min: 0, max: 100
      default 100
    end
  end

  calculations do
    calculate :total_fights, :integer, expr(fights_won + fights_lost) do
      description "Total number of fights (won + lost)"
    end

    calculate :win_rate,
              :float,
              expr(
                if total_fights > 0 do
                  fights_won / total_fights
                else
                  0.0
                end
              )

    calculate :is_healthy, :boolean, expr(health > 50) do
      description "Whether the superhero is in good health (>50 HP)"
    end
  end
end
