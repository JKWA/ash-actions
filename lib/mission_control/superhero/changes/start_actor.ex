defmodule MissionControl.Superhero.Changes.StartActor do
  use Ash.Resource.Change
  require Logger

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, superhero ->
      case start_actor(superhero) do
        {:ok, _pid} ->
          Logger.info("Started actor for #{superhero.alias || superhero.name}")
          {:ok, superhero}

        {:error, {:already_started, _pid}} ->
          Logger.debug("Actor already running for #{superhero.alias || superhero.name}")
          {:ok, superhero}

        {:error, reason} ->
          Logger.error(
            "Failed to start actor for #{superhero.alias || superhero.name}: #{inspect(reason)}"
          )

          {:error,
           Ash.Error.Changes.InvalidChanges.exception(
             message: "Failed to start superhero actor: #{inspect(reason)}"
           )}
      end
    end)
  end

  defp start_actor(superhero) do
    child_spec = %{
      id: MissionControl.Superhero.Actor,
      start: {MissionControl.Superhero.Actor, :start_link, [superhero.id]},
      restart: :temporary
    }

    DynamicSupervisor.start_child(MissionControl.SuperheroSupervisor, child_spec)
  end
end
