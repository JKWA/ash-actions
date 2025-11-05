defmodule MissionControl.Assignment.Changes.ReleaseSuperheroBestEffort do
  use Ash.Resource.Change
  import Funx.Monad
  import Funx.Monad.Either
  require Logger

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, assignment ->
      load_superhero(assignment)
      |> bind(&off_duty_superhero/1)
      |> bind(&tap_broadcast_off_duty_superhero/1)
      |> map(fn _ -> assignment end)
      |> map_left(fn _ -> assignment end)
      |> to_result()
    end)
  end

  defp load_superhero(assignment) do
    MissionControl.get_superhero(assignment.superhero_id)
    |> from_result()
  end

  defp off_duty_superhero(superhero) do
    superhero
    |> Ash.Changeset.for_action(:off_duty)
    |> Ash.update(domain: MissionControl)
    |> from_result()
  end

  defp tap_broadcast_off_duty_superhero(updated_superhero) do
    broadcast_update(MissionControl.Superhero, updated_superhero)
    right(updated_superhero)
  end

  defp broadcast_update(resource, record) do
    notification =
      Ash.Notifier.Notification.new(
        resource,
        data: record,
        action: %{type: :update}
      )

    Phoenix.PubSub.broadcast(
      MissionControl.PubSub,
      "#{resource_prefix(resource)}:#{record.id}",
      %{
        topic: "#{resource_prefix(resource)}:#{record.id}",
        payload: notification
      }
    )
  end

  defp resource_prefix(MissionControl.Superhero), do: "superhero"
end
