defmodule MissionControl.Assignment do
  use Ash.Resource,
    otp_app: :mission_control,
    domain: MissionControl,
    data_layer: Ash.DataLayer.Ets,
    notifiers: [Ash.Notifier.PubSub]

  alias MissionControl.Assignment.Changes.{
    EnforceSingleAssignment,
    DispatchSuperhero,
    ReleaseSuperheroBestEffort,
    AutoCloseOnResult
  }

  alias MissionControl.Assignment.Validations.{MustBeOpen, MustBeClosed, CheckBeforeDelete}
  alias MissionControl.Assignment.Calculations.{Closed, MaybeSuperhero}

  actions do
    defaults [:read]

    read :by_superhero do
      argument :superhero_id, :uuid, allow_nil?: false
      filter expr(superhero_id == ^arg(:superhero_id) and status != :closed)
    end

    create :create do
      accept [:superhero_id, :name]
      primary? true
      change EnforceSingleAssignment
    end

    update :update do
      accept [:status, :result]
      primary? true
    end

    update :dispatch do
      require_atomic? false
      accept []
      validate MustBeOpen
      change set_attribute(:status, :dispatched)
      change DispatchSuperhero
    end

    update :start_fighting do
      require_atomic? false
      accept []
      change set_attribute(:status, :fighting)
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

    update :update_result do
      require_atomic? false
      accept [:result]
      change AutoCloseOnResult
      change ReleaseSuperheroBestEffort
    end

    destroy :destroy do
      primary? true
      require_atomic? false
      validate CheckBeforeDelete
      change ReleaseSuperheroBestEffort
    end

    destroy :force_destroy do
      require_atomic? false
    end
  end

  pub_sub do
    module MissionControlWeb.Endpoint
    prefix "assignment"

    publish :create, ["created"]
    publish :update, [:_pkey]
    publish :update_result, [:_pkey]
    publish :start_fighting, [:_pkey]
    publish :destroy, [:_pkey]
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :status, :atom do
      allow_nil? false
      public? true
      constraints one_of: [:open, :dispatched, :fighting, :closed]
      default :open
    end

    attribute :result, :atom do
      public? true
      constraints one_of: [:won, :lost, :unknown]
      default :unknown
    end

    timestamps()
  end

  calculations do
    calculate :closed?, :boolean, Closed
    calculate :maybe_superhero, :struct, MaybeSuperhero
  end

  relationships do
    belongs_to :superhero, MissionControl.Superhero do
      allow_nil? false
    end
  end

  def closed?(%{status: status}), do: status == :closed
  def won?(%{result: result}), do: result == :won
end
