defmodule MissionControl.Superhero do
  use Ash.Resource,
    otp_app: :mission_control,
    domain: MissionControl,
    data_layer: Ash.DataLayer.Ets,
    notifiers: [Ash.Notifier.PubSub]

  alias MissionControl.Superhero.Validations.{
    MustBeOnDuty,
    MustBeOffDuty,
    MustBeWorking,
    AliasIsUnique
  }

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name, :alias]
    end

    read :get_by_id do
      get? true
      argument :id, :uuid, allow_nil?: false
      filter expr(id == ^arg(:id))
    end

    update :update do
      require_atomic? false
      primary? true
      accept [:name, :alias, :status, :fights_won, :fights_lost, :health]
      validate AliasIsUnique, where: [changing(:alias)]
    end

    update :fight_crime do
      require_atomic? false
      argument :difficulty, :integer, allow_nil?: false, default: 1
      change MissionControl.Changes.FightCrime
    end

    update :dispatch do
      require_atomic? false
      accept []
      validate MustBeOnDuty
      change set_attribute(:status, :dispatched)
    end

    update :on_duty do
      require_atomic? false
      accept []
      validate MustBeOffDuty
      change set_attribute(:status, :on_duty)
    end

    update :off_duty do
      require_atomic? false
      accept []
      validate MustBeWorking
      change set_attribute(:status, :off_duty)
    end
  end

  pub_sub do
    module MissionControlWeb.Endpoint
    prefix "superhero"

    publish :create, ["created"]
    publish :update, [:_pkey]
    publish :destroy, [:_pkey]
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

    attribute :status, :atom do
      description "The current duty status of the superhero"
      allow_nil? false
      public? true
      constraints one_of: [:on_duty, :dispatched, :off_duty]
      default :off_duty
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

    calculate :is_free, :boolean, expr(status == :off_duty) do
      description "Whether the superhero is free to take on a new assignment"
    end
  end

  # Domain Logic - for use in code where you can't use calculations
  def on_duty?(%{status: status}), do: status == :on_duty

  def free?(%{status: status}), do: status == :off_duty

  def off_duty?(%{status: status}), do: status == :off_duty

  def dispatched?(%{status: status}), do: status == :dispatched

  def working?(%{} = superhero) do
    predicate = Funx.Predicate.p_any([&dispatched?/1, &on_duty?/1])
    predicate.(superhero)
  end
end
