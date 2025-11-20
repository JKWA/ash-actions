defmodule MissionControl.Superhero.Changes.NotifyActor do
  use Ash.Resource.Change
  require Logger

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, superhero ->
      message = action_to_message(changeset.action.name)

      case notify_actor(superhero.id, message) do
        :ok ->
          {:ok, superhero}

        {:error, :actor_dead} ->
          Logger.warning(
            "Actor dead after #{changeset.action.name}, cleaning up superhero #{superhero.name}"
          )

          cleanup_dead_superhero(superhero)

          {:error,
           Ash.Error.Changes.InvalidChanges.exception(message: "Superhero actor is not running")}
      end
    end)
  end

  defp action_to_message(:dispatch), do: :dispatched
  defp action_to_message(:on_duty), do: :went_on_duty
  defp action_to_message(:off_duty), do: :went_off_duty
  defp action_to_message(:recovery), do: :went_to_recovery

  defp notify_actor(superhero_id, message) do
    case Registry.lookup(MissionControl.SuperheroRegistry, superhero_id) do
      [{pid, _}] ->
        send(pid, message)
        :ok

      [] ->
        {:error, :actor_dead}
    end
  end

  defp cleanup_dead_superhero(superhero) do
    case MissionControl.delete_superhero(superhero) do
      :ok ->
        Logger.info("Cleaned up dead superhero #{superhero.name} from database")

      {:error, reason} ->
        Logger.error("Failed to cleanup dead superhero: #{inspect(reason)}")
    end
  end
end
