defmodule MissionControl.Assignment.Changes.DispatchSuperhero do
  use Ash.Resource.Change

  import Funx.Monad
  import Funx.Monad.Either
  import Funx.Foldable
  import Funx.Utils

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, assignment ->
      load_superhero(assignment)
      |> bind(&dispatch_superhero/1)
      |> map(&broadcast_dispatch_tap/1)
      |> map_left(curry_r(&handle_dispatch_error/2).(assignment))
      |> map(fn _ -> assignment end)
      |> to_result()
    end)
  end

  defp load_superhero(assignment) do
    MissionControl.get_superhero(assignment.superhero_id)
    |> from_result()
    |> map_left(curry_r(&format_superhero_error/2).(assignment))
  end

  defp dispatch_superhero(superhero) do
    superhero
    |> MissionControl.dispatch_superhero()
    |> from_result()
  end

  defp broadcast_dispatch_tap(updated_superhero) do
    broadcast_update(MissionControl.Superhero, updated_superhero)
    updated_superhero
  end

  defp handle_dispatch_error(error, assignment) do
    rollback_assignment(assignment)
    |> fold_l(
      fn rollback_error -> aggregate_errors(error, rollback_error) end,
      fn _ -> error end
    )
  end

  defp rollback_assignment(assignment) do
    assignment
    |> Ash.Changeset.for_action(:update, %{status: :open})
    |> Ash.update()
    |> from_result()
  end

  defp format_superhero_error(%Ash.Error.Query.NotFound{}, assignment) do
    Ash.Error.Changes.InvalidChanges.exception(
      fields: [:superhero_id],
      message:
        "Cannot dispatch assignment: superhero with ID #{assignment.superhero_id} not found"
    )
  end

  defp format_superhero_error(error, _assignment), do: error

  defp aggregate_errors(%Ash.Error.Invalid{errors: e1}, %Ash.Error.Invalid{errors: e2}),
    do: %Ash.Error.Invalid{errors: e1 ++ e2}

  defp aggregate_errors(e1, e2),
    do: Ash.Error.to_error_class([e1, e2])

  defp broadcast_update(resource, record) do
    notification =
      Ash.Notifier.Notification.new(resource,
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
