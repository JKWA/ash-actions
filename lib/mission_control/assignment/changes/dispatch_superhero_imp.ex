# credo:disable-for-this-file

defmodule MissionControl.Assignment.Changes.DispatchSuperhero_Imp do
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, assignment ->
      case MissionControl.get_superhero(assignment.superhero_id) do
        {:ok, %MissionControl.Superhero{} = superhero} ->
          case MissionControl.dispatch_superhero(superhero) do
            {:ok, updated_superhero} ->
              broadcast_update(MissionControl.Superhero, updated_superhero)
              {:ok, assignment}

            {:error, dispatch_error} ->
              case rollback_assignment(assignment) do
                {:ok, _} ->
                  {:error, dispatch_error}

                {:error, rollback_error} ->
                  {:error, aggregate_errors(dispatch_error, rollback_error)}
              end
          end

        {:error, %Ash.Error.Query.NotFound{}} ->
          error =
            Ash.Error.Changes.InvalidChanges.exception(
              fields: [:superhero_id],
              message:
                "Cannot dispatch assignment: superhero with ID #{assignment.superhero_id} not found"
            )

          case rollback_assignment(assignment) do
            {:ok, _} ->
              {:error, error}

            {:error, rollback_error} ->
              {:error, aggregate_errors(error, rollback_error)}
          end

        {:error, other_error} ->
          case rollback_assignment(assignment) do
            {:ok, _} ->
              {:error, other_error}

            {:error, rollback_error} ->
              {:error, aggregate_errors(other_error, rollback_error)}
          end
      end
    end)
  end

  defp rollback_assignment(assignment) do
    assignment
    |> Ash.Changeset.for_action(:update, %{status: :open})
    |> Ash.update()
  end

  defp aggregate_errors(%Ash.Error.Invalid{errors: e1}, %Ash.Error.Invalid{errors: e2}),
    do: %Ash.Error.Invalid{errors: e1 ++ e2}

  defp aggregate_errors(e1, e2),
    do: Ash.Error.to_error_class([e1, e2])

  defp broadcast_update(resource, record) do
    topic = "#{resource_prefix(resource)}:#{record.id}"

    notification =
      Ash.Notifier.Notification.new(resource,
        data: record,
        action: %{type: :update}
      )

    Phoenix.PubSub.broadcast(
      MissionControl.PubSub,
      topic,
      %{topic: topic, payload: notification}
    )
  end

  defp resource_prefix(MissionControl.Superhero), do: "superhero"
end
