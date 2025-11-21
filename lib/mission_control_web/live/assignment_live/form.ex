defmodule MissionControlWeb.AssignmentLive.Form do
  use MissionControlWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage assignment records in your database.</:subtitle>
      </.header>

      <.form
        for={@form}
        id="assignment-form"
        phx-change="validate"
        phx-submit="save"
      >
        <%= if @form.source.type == :update do %>
          <.input
            field={@form[:name]}
            type="text"
            label="Name"
          />
          <.input
            field={@form[:status]}
            type="select"
            label="Status"
            options={[
              {"Open", :open},
              {"Dispatched", :dispatched},
              {"Closed", :closed}
            ]}
          />
        <% end %>

        <.button phx-disable-with="Saving..." variant="primary">Save Assignment</.button>
        <.button navigate={return_path(@return_to, @assignment)}>Cancel</.button>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    assignment =
      case params["id"] do
        nil -> nil
        id -> Ash.get!(MissionControl.Assignment, id)
      end

    action = if is_nil(assignment), do: "New", else: "Edit"
    page_title = action <> " " <> "Assignment"

    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(assignment: assignment)
     |> assign(:page_title, page_title)
     |> assign_form()}
  end

  defp return_to("show"), do: "show"
  defp return_to("dispatch"), do: "dispatch"
  defp return_to(_), do: "index"

  @impl true
  def handle_event("validate", %{"assignment" => assignment_params}, socket) do
    {:noreply,
     assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, assignment_params))}
  end

  def handle_event("save", %{"assignment" => assignment_params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: assignment_params) do
      {:ok, assignment} ->
        notify_parent({:saved, assignment})

        socket =
          socket
          |> put_flash(:info, "Assignment #{socket.assigns.form.source.type}d successfully")
          |> push_navigate(to: return_path(socket.assigns.return_to, assignment))

        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, form: form)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(%{assigns: %{assignment: assignment}} = socket) do
    form =
      if assignment do
        AshPhoenix.Form.for_update(assignment, :update, as: "assignment")
      else
        AshPhoenix.Form.for_create(MissionControl.Assignment, :create, as: "assignment")
      end

    assign(socket, form: to_form(form))
  end

  defp return_path("index", _assignment), do: ~p"/assignments"
  defp return_path("show", assignment), do: ~p"/assignments/#{assignment.id}"
  defp return_path("dispatch", _assignment), do: ~p"/"
end
