defmodule MissionControlWeb.DispatchLive.Index do
  use MissionControlWeb, :live_view
  require Logger
  require Ash.Query
  alias MissionControl.Superhero

  @impl true
  def mount(_params, _session, socket) do
    show_closed = true

    superheroes =
      Superhero
      |> Ash.Query.sort(healthy?: :asc, alias: :asc)
      |> Ash.Query.load(:healthy?)
      |> Ash.read!()
      |> Ash.load!([:win_rate])

    assignments = list_assignments(show_closed)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(MissionControl.PubSub, "assignment:created")
      Phoenix.PubSub.subscribe(MissionControl.PubSub, "superhero:created")

      Enum.each(superheroes, fn superhero ->
        Phoenix.PubSub.subscribe(MissionControl.PubSub, "superhero:#{superhero.id}")
      end)

      Enum.each(assignments, fn assignment ->
        Phoenix.PubSub.subscribe(MissionControl.PubSub, "assignment:#{assignment.id}")
      end)
    end

    socket =
      socket
      |> assign(:page_title, "Dispatch")
      |> assign(:show_closed, show_closed)
      |> stream(:superheroes, superheroes, id_key: :id)
      |> stream(:assignments, assignments, id_key: :id)

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_closed", _params, socket) do
    new_value = !socket.assigns.show_closed
    Logger.info("Toggling show_closed from #{socket.assigns.show_closed} to #{new_value}")

    assignments = list_assignments(new_value)

    {:noreply,
     socket
     |> assign(:show_closed, new_value)
     |> stream(:assignments, assignments, reset: true)}
  end

  @impl true
  def handle_event("terminate_superhero", %{"id" => id}, socket) do
    case Registry.lookup(MissionControl.SuperheroRegistry, id) do
      [{pid, _}] ->
        send(pid, :terminate)
        {:noreply, put_flash(socket, :info, "Superhero terminated")}

      [] ->
        {:noreply, put_flash(socket, :error, "Superhero already terminated")}
    end
  end

  @impl true
  def handle_event("superhero_on_duty", %{"id" => id}, socket) do
    superhero = Ash.get!(Superhero, id)

    Logger.debug(inspect(superhero, label: "Setting superhero"))

    case MissionControl.on_duty_superhero(superhero) do
      {:ok, updated_superhero} ->
        updated_superhero = Ash.load!(updated_superhero, [:win_rate, :healthy?])
        {:noreply, stream_insert(socket, :superheroes, updated_superhero)}

      {:error, error} ->
        handle_error(error, "on duty", socket)
    end
  end

  @impl true
  def handle_event("superhero_off_duty", %{"id" => id}, socket) do
    superhero = Ash.get!(Superhero, id)

    case MissionControl.off_duty_superhero(superhero) do
      {:ok, updated_superhero} ->
        updated_superhero = Ash.load!(updated_superhero, [:win_rate, :healthy?])
        {:noreply, stream_insert(socket, :superheroes, updated_superhero)}

      {:error, error} ->
        handle_error(error, "off duty", socket)
    end
  end

  @impl true
  def handle_event("superhero_recovery", %{"id" => id}, socket) do
    superhero = Ash.get!(Superhero, id)

    case MissionControl.recovery_superhero(superhero) do
      {:ok, updated_superhero} ->
        updated_superhero = Ash.load!(updated_superhero, [:win_rate, :healthy?])
        {:noreply, stream_insert(socket, :superheroes, updated_superhero)}

      {:error, error} ->
        handle_error(error, "off duty", socket)
    end
  end

  @impl true
  def handle_event("superhero_assign", %{"id" => id}, socket) do
    superhero = Ash.get!(Superhero, id)

    case MissionControl.create_assignment(%{
           superhero_id: superhero.id,
           name: superhero.alias <> " Assignment"
         }) do
      {:ok, _assignment} ->
        {:noreply, socket}

      {:error, error} ->
        handle_error(error, "create assignment", socket)
    end
  end

  @impl true
  def handle_event("dispatch_assignment", %{"id" => id}, socket) do
    assignment = Ash.get!(MissionControl.Assignment, id)

    case MissionControl.dispatch_assignment(assignment) do
      {:ok, updated_assignment} ->
        updated_assignment = Ash.load!(updated_assignment, [:closed?, :maybe_superhero])

        {:noreply,
         socket
         |> stream_insert(:assignments, updated_assignment)}

      {:error, error} ->
        handle_error(error, "dispatch assignment", socket)
    end
  end

  @impl true
  def handle_event("assignment_close", %{"id" => id}, socket) do
    assignment = Ash.get!(MissionControl.Assignment, id)

    case MissionControl.close_assignment(assignment) do
      {:ok, updated_assignment} ->
        updated_assignment = Ash.load!(updated_assignment, [:closed?, :maybe_superhero])

        {:noreply,
         socket
         |> stream_insert(:assignments, updated_assignment)}

      {:error, error} ->
        handle_error(error, "close assignment", socket)
    end
  end

  @impl true
  def handle_event("assignment_reopen", %{"id" => id}, socket) do
    assignment = Ash.get!(MissionControl.Assignment, id)

    case MissionControl.reopen_assignment(assignment) do
      {:ok, updated_assignment} ->
        updated_assignment = Ash.load!(updated_assignment, [:closed?, :maybe_superhero])

        {:noreply,
         socket
         |> stream_insert(:assignments, updated_assignment)}

      {:error, error} ->
        handle_error(error, "close assignment", socket)
    end
  end

  @impl true
  def handle_event("assignment_delete", %{"id" => id}, socket) do
    assignment = Ash.get!(MissionControl.Assignment, id)

    case Ash.destroy(assignment) do
      :ok ->
        {:noreply, stream_delete(socket, :assignments, assignment)}

      {:ok, _} ->
        {:noreply, stream_delete(socket, :assignments, assignment)}

      {:error, error} ->
        handle_error(error, "delete assignment", socket)
    end
  end

  @impl true
  def handle_info(
        %{topic: "assignment:created", payload: %Ash.Notifier.Notification{data: assignment}},
        socket
      ) do
    Phoenix.PubSub.subscribe(MissionControl.PubSub, "assignment:#{assignment.id}")

    assignment = Ash.load!(assignment, [:closed?, :maybe_superhero])

    {:noreply, stream_insert(socket, :assignments, assignment, at: 0)}
  end

  @impl true
  def handle_info(
        %{
          topic: "assignment:" <> _id,
          payload: %Ash.Notifier.Notification{action: %{type: :destroy}, data: assignment}
        },
        socket
      ) do
    {:noreply, stream_delete(socket, :assignments, assignment)}
  end

  @impl true
  def handle_info(
        %{topic: "assignment:" <> _id, payload: %Ash.Notifier.Notification{data: assignment}},
        socket
      ) do
    assignment = Ash.load!(assignment, [:closed?, :maybe_superhero])

    {:noreply, stream_insert(socket, :assignments, assignment)}
  end

  @impl true
  def handle_info(
        %{topic: "superhero:created", payload: %Ash.Notifier.Notification{data: superhero}},
        socket
      ) do
    Phoenix.PubSub.subscribe(MissionControl.PubSub, "superhero:#{superhero.id}")
    superhero = Ash.load!(superhero, [:win_rate, :healthy?])
    {:noreply, stream_insert(socket, :superheroes, superhero)}
  end

  @impl true
  def handle_info(
        %{
          topic: "superhero:" <> _id,
          payload: %Ash.Notifier.Notification{action: %{type: :destroy}, data: superhero}
        },
        socket
      ) do
    {:noreply, stream_delete(socket, :superheroes, superhero)}
  end

  @impl true
  def handle_info(
        %{topic: "superhero:" <> _id, payload: %Ash.Notifier.Notification{data: superhero}},
        socket
      ) do
    superhero = Ash.load!(superhero, [:win_rate, :healthy?])
    {:noreply, stream_insert(socket, :superheroes, superhero)}
  end

  defp list_assignments(show_closed) do
    MissionControl.Assignment
    |> maybe_filter_closed(show_closed)
    |> Ash.Query.sort(closed?: :asc, inserted_at: :desc)
    |> Ash.Query.load(:closed?)
    |> Ash.read!()
    |> Ash.load!([:maybe_superhero])
  end

  defp maybe_filter_closed(query, true), do: query
  defp maybe_filter_closed(query, false), do: Ash.Query.filter(query, closed?: false)

  defp handle_error(error, operation_name, socket) do
    Logger.error("#{operation_name} failed: #{inspect(error, pretty: true)}")
    message = extract_error_message(error, "Failed to #{operation_name}")
    {:noreply, put_flash(socket, :error, message)}
  end

  defp extract_error_message(%Ash.Error.Invalid{errors: errors}, default_message) do
    errors
    |> Enum.reject(&unknown_error?/1)
    |> Enum.find_value(&get_error_message/1)
    |> case do
      nil -> default_message
      message -> message
    end
  end

  defp extract_error_message(_error, default_message), do: default_message

  defp unknown_error?(%Ash.Error.Unknown.UnknownError{}), do: true
  defp unknown_error?(_), do: false

  defp get_error_message(%Ash.Error.Query.NotFound{resource: Superhero}) do
    "Superhero not found"
  end

  defp get_error_message(%{message: message}) when is_binary(message), do: message
  defp get_error_message(_), do: nil

  defp status_badge_class(:open), do: "badge-success"
  defp status_badge_class(:dispatched), do: "badge-warning"
  defp status_badge_class(:closed), do: "badge-neutral"
  defp status_badge_class(_), do: "badge-primary"

  defp superhero_status_badge_class(:off_duty), do: "badge-success"
  defp superhero_status_badge_class(:on_duty), do: "badge-info"
  defp superhero_status_badge_class(:dispatched), do: "badge-warning"
  defp superhero_status_badge_class(_), do: "badge-primary"

  defp status_border_class(:open), do: "border-l-4 border-success"
  defp status_border_class(:dispatched), do: "border-l-4 border-warning"
  defp status_border_class(:closed), do: "border-l-4 border-neutral"
  defp status_border_class(_), do: "border-l-4 border-primary"

  defp superhero_status_border_class(:off_duty), do: "border-l-4 border-success"
  defp superhero_status_border_class(:on_duty), do: "border-l-4 border-info"
  defp superhero_status_border_class(:dispatched), do: "border-l-4 border-warning"
  defp superhero_status_border_class(_), do: "border-l-4 border-primary"
end
