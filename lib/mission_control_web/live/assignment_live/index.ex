defmodule MissionControlWeb.AssignmentLive.Index do
  use MissionControlWeb, :live_view
  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Assignments
        <:actions>
          <.button variant="primary" navigate={~p"/assignments/new"}>
            <.icon name="hero-plus" /> New Assignment
          </.button>
        </:actions>
      </.header>

      <.table
        id="assignments"
        rows={@streams.assignments}
        row_click={fn {_id, assignment} -> JS.navigate(~p"/assignments/#{assignment}") end}
      >
        <:col :let={{_id, assignment}} label="Id">{assignment.id}</:col>

        <:col :let={{_id, assignment}} label="Name">{assignment.name}</:col>

        <:col :let={{_id, assignment}} label="Superhero Id">{assignment.superhero_id}</:col>

        <:col :let={{_id, assignment}} label="Difficulty">{assignment.difficulty}</:col>

        <:col :let={{_id, assignment}} label="Status">{assignment.status}</:col>

        <:col :let={{_id, assignment}} label="Result">{assignment.result}</:col>

        <:col :let={{_id, assignment}} label="Health cost">{assignment.health_cost}</:col>

        <:action :let={{_id, assignment}}>
          <div class="sr-only">
            <.link navigate={~p"/assignments/#{assignment}"}>Show</.link>
          </div>

          <.link navigate={~p"/assignments/#{assignment}/edit"}>Edit</.link>
        </:action>

        <:action :let={{_id, assignment}}>
          <.link phx-click={JS.push("dispatch", value: %{id: assignment.id})}>
            Dispatch
          </.link>
        </:action>

        <:action :let={{id, assignment}}>
          <.link
            phx-click={JS.push("delete", value: %{id: assignment.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(MissionControl.PubSub, "assignment:created")
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Assignments")
     |> stream(:assignments, Ash.read!(MissionControl.Assignment))}
  end

  @impl true
  def handle_event("dispatch", %{"id" => id}, socket) do
    assignment = Ash.get!(MissionControl.Assignment, id)

    case MissionControl.dispatch_assignment(assignment) do
      {:ok, updated_assignment} ->
        {:noreply,
         socket
         |> put_flash(:info, "Assignment dispatched successfully!")
         |> stream_insert(:assignments, updated_assignment)}

      {:error, error} ->
        Logger.error("Assignment dispatch failed: #{inspect(error, pretty: true)}")
        message = extract_error_message(error)
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    assignment = Ash.get!(MissionControl.Assignment, id)
    Ash.destroy!(assignment)

    {:noreply, stream_delete(socket, :assignments, assignment)}
  end

  @impl true
  def handle_info(
        %{topic: "assignment:created", payload: %Ash.Notifier.Notification{data: assignment}},
        socket
      ) do
    {:noreply, stream_insert(socket, :assignments, assignment)}
  end

  defp extract_error_message(%Ash.Error.Invalid{errors: errors}) do
    errors
    |> Enum.reject(&unknown_error?/1)
    |> Enum.find_value(&get_error_message/1)
    |> case do
      nil -> "Failed to dispatch assignment"
      message -> message
    end
  end

  defp extract_error_message(_error), do: "Failed to dispatch assignment"

  defp unknown_error?(%Ash.Error.Unknown.UnknownError{}), do: true
  defp unknown_error?(_), do: false

  defp get_error_message(%Ash.Error.Query.NotFound{resource: MissionControl.Superhero}) do
    "Superhero not found"
  end

  defp get_error_message(%{message: message}) when is_binary(message), do: message
  defp get_error_message(_), do: nil
end
