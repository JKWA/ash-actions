defmodule MissionControl do
  use Ash.Domain,
    otp_app: :mission_control

  resources do
    resource MissionControl.Superhero
    resource MissionControl.Assignment
  end
end
