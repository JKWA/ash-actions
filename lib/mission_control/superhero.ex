defmodule MissionControl.Superhero do
  use Ash.Resource,
    otp_app: :mission_control,
    domain: MissionControl,
    data_layer: Ash.DataLayer.Ets,
    notifiers: [Ash.Notifier.PubSub, MissionControl.Superhero.Notifiers.ActorNotifier]

  import Funx.Predicate

  alias MissionControl.Superhero.Validations.{
    MustBeOnDuty,
    MustBeOffDuty,
    MustBeFree,
    MustBeWorking
  }

  alias MissionControl.Superhero.Calculations.{
    WinRate,
    Healthy
  }

  alias MissionControl.Superhero.Changes.{NotifyActor, StartActor}

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name, :alias]
      change StartActor
    end

    read :get_by_id do
      get? true
      argument :id, :uuid, allow_nil?: false
      filter expr(id == ^arg(:id))
    end

    update :update do
      require_atomic? false
      primary? true
      accept [:name, :alias, :status, :health]
    end

    update :dispatch do
      require_atomic? false
      accept []
      validate MustBeOnDuty
      change set_attribute(:status, :dispatched)
      change NotifyActor
    end

    update :on_duty do
      require_atomic? false
      accept []
      validate MustBeFree
      change set_attribute(:status, :on_duty)
      change NotifyActor
    end

    update :off_duty do
      require_atomic? false
      accept []
      validate MustBeWorking
      change set_attribute(:status, :off_duty)
      change NotifyActor
    end

    update :recovery do
      require_atomic? false
      accept []
      validate MustBeOffDuty
      change set_attribute(:status, :recovery)
      change NotifyActor
    end

    update :update_health do
      require_atomic? false
      accept [:health]
    end
  end

  pub_sub do
    module MissionControlWeb.Endpoint
    prefix "superhero"

    publish :create, ["created"]
    publish :update, [:_pkey]
    publish :update_health, [:_pkey]
    publish :on_duty, [:_pkey]
    publish :off_duty, [:_pkey]
    publish :dispatch, [:_pkey]
    publish :recovery, [:_pkey]
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
      constraints one_of: [:on_duty, :dispatched, :off_duty, :recovery]
      default :off_duty
    end

    attribute :health, :integer do
      description "Current health points (0-100)"
      allow_nil? false
      public? true
      constraints min: 0, max: 100
      default 100
    end
  end

  relationships do
    has_many :assignments, MissionControl.Assignment do
      destination_attribute :superhero_id
    end
  end

  calculations do
    calculate :win_rate, :float, WinRate

    calculate :healthy?, :boolean, {Healthy, threshold: 50}
  end

  def on_duty?(%{status: status}), do: status == :on_duty

  def off_duty?(%{status: status}), do: status == :off_duty

  def dispatched?(%{status: status}), do: status == :dispatched

  def recovery?(%{status: status}), do: status == :recovery

  defp working_predicate do
    p_any([&dispatched?/1, &on_duty?/1, &recovery?/1])
  end

  def working?(%{} = superhero) do
    working_predicate().(superhero)
  end

  def free?(%{} = superhero) do
    p_not(working_predicate()).(superhero)
  end
end
