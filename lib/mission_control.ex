defmodule MissionControl do
  use Ash.Domain,
    otp_app: :mission_control

  resources do
    resource MissionControl.Superhero do
      define :get_superhero, action: :get_by_id, args: [:id]
      define :list_superheroes, action: :read
      define :create_superhero, action: :create
      define :update_superhero, action: :update
      define :update_health_superhero, action: :update_health
      define :delete_superhero, action: :destroy
      define :on_duty_superhero, action: :on_duty
      define :off_duty_superhero, action: :off_duty
      define :recovery_superhero, action: :recovery
      define :dispatch_superhero, action: :dispatch
    end

    resource MissionControl.Assignment do
      define :get_assignment, action: :read, args: [:id]
      define :list_assignments, action: :read
      define :list_assignments_by_superhero, action: :by_superhero, args: [:superhero_id]
      define :create_assignment, action: :create
      define :update_assignment, action: :update
      define :dispatch_assignment, action: :dispatch
      define :start_fighting_assignment, action: :start_fighting
      define :update_result_assignment, action: :update_result
      define :close_assignment, action: :close
      define :reopen_assignment, action: :reopen
      define :delete_assignment, action: :destroy
      define :force_delete_assignment, action: :force_destroy
    end
  end
end
