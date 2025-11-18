defmodule MissionControl.Assignment do
  use Ash.Resource,
    otp_app: :mission_control,
    domain: MissionControl,
    data_layer: Ash.DataLayer.Ets,
    notifiers: [Ash.Notifier.PubSub]

  alias MissionControl.Assignment.Changes.{
    EnforceSingleAssignment,
    DispatchSuperhero,
    ReleaseSuperheroBestEffort
  }

  alias MissionControl.Assignment.Validations.{MustBeOpen, MustBeClosed, CheckBeforeDelete}

  actions do
    defaults [:read]

    read :by_superhero do
      argument :superhero_id, :uuid, allow_nil?: false
      filter expr(superhero_id == ^arg(:superhero_id) and status != :closed)
    end

    create :create do
      accept [:superhero_id, :name, :difficulty]
      primary? true
      change EnforceSingleAssignment
    end

    update :update do
      accept [:status, :result, :health_cost]
      primary? true
    end

    update :dispatch do
      require_atomic? false
      accept []
      validate MustBeOpen
      change set_attribute(:status, :dispatched)
      change DispatchSuperhero
    end

    update :close do
      require_atomic? false
      accept []
      change set_attribute(:status, :closed)
      change ReleaseSuperheroBestEffort
    end

    update :reopen do
      require_atomic? false
      accept []
      validate MustBeClosed
      change set_attribute(:status, :open)
      change EnforceSingleAssignment
    end

    destroy :destroy do
      primary? true
      require_atomic? false
      validate CheckBeforeDelete
      change ReleaseSuperheroBestEffort
    end
  end

  pub_sub do
    module MissionControlWeb.Endpoint
    prefix "assignment"

    publish :create, ["created"]
    publish :update, [:_pkey]
    publish :destroy, [:_pkey]
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :difficulty, :integer do
      allow_nil? false
      public? true
    end

    attribute :status, :atom do
      allow_nil? false
      public? true
      constraints one_of: [:open, :dispatched, :fighting, :closed]
      default :open
    end

    attribute :result, :string do
      public? true
    end

    attribute :health_cost, :integer do
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :superhero, MissionControl.Superhero do
      allow_nil? false
    end
  end
end
