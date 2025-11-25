defmodule MissionControl.Assignment.Changes.AutoCloseOnResult do
  @moduledoc """
  Automatically closes the assignment when result is set to :won or :lost.

  Delegates to the :close action, which handles:
  - Setting status to :closed
  - Releasing the superhero (via ReleaseSuperheroBestEffort)
  """
  use Ash.Resource.Change
  require Logger

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, assignment ->
      if assignment.result in [:won, :lost] and assignment.status != :closed do
        Logger.info("Assignment result is #{assignment.result}, auto-closing assignment #{assignment.name}")

        # Use the domain interface to close the assignment
        case MissionControl.close_assignment(assignment) do
          {:ok, updated_assignment} ->
            {:ok, updated_assignment}

          {:error, error} ->
            Logger.error("Failed to auto-close assignment: #{inspect(error)}")
            # Return original assignment, don't fail the update_result
            {:ok, assignment}
        end
      else
        {:ok, assignment}
      end
    end)
  end
end
