defmodule MissionControl.Assignment do
  use Ash.Resource,
    otp_app: :mission_control,
    domain: MissionControl,
    data_layer: Ash.DataLayer.Ets

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:superhero_id, :difficulty]
      change set_attribute(:status, "fighting")
      change MissionControl.Changes.StartAssignment
    end

    update :update do
      accept [:status, :result, :health_cost]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :difficulty, :integer do
      allow_nil? false
      public? true
    end

    attribute :status, :string do
      allow_nil? false
      public? true
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
