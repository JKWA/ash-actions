defmodule MissionControlWeb.SuperheroLive.Form do
  use MissionControlWeb, :live_view
  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage superheroes in memory (ETS).</:subtitle>
      </.header>

      <.form for={@form} id="superhero-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} label="Name" />
        <.input field={@form[:alias]} label="Alias" />
        <.input field={@form[:is_patrolling]} type="checkbox" label="Is Patrolling?" />
        <.input field={@form[:fights_won]} type="number" label="Fights Won" />
        <.input field={@form[:fights_lost]} type="number" label="Fights Lost" />
        <.input field={@form[:health]} type="number" label="Health" />

        <div class="mt-4 flex gap-2">
          <.button phx-disable-with="Saving..." variant="primary">Save Superhero</.button>
          <.button navigate={return_path(@return_to, @superhero)}>Cancel</.button>
        </div>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    superhero =
      case params["id"] do
        nil -> nil
        id -> Ash.get!(MissionControl.Superhero, id)
      end

    action = if is_nil(superhero), do: "New", else: "Edit"
    page_title = "#{action} Superhero"

    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(:superhero, superhero)
     |> assign(:page_title, page_title)
     |> assign_form()}
  end

  @impl true
  def handle_event("validate", %{"superhero" => params}, socket) do
    {:noreply, assign(socket, form: AshPhoenix.Form.validate(socket.assigns.form, params))}
  end

  def handle_event("save", %{"superhero" => params}, socket) do
    Logger.info("Save event triggered with params: #{inspect(params)}")
    Logger.info("Form state before submit: #{inspect(socket.assigns.form)}")

    case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
      {:ok, superhero} ->
        Logger.info("Successfully saved superhero: #{inspect(superhero)}")
        notify_parent({:saved, superhero})

        socket =
          socket
          |> put_flash(:info, "Superhero #{socket.assigns.form.source.type}d successfully")
          |> push_navigate(to: return_path(socket.assigns.return_to, superhero))

        {:noreply, socket}

      {:error, form} ->
        Logger.error("Failed to save superhero. Form errors: #{inspect(form.errors)}")
        Logger.error("Full form state: #{inspect(form)}")
        {:noreply, assign(socket, form: form)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp assign_form(%{assigns: %{superhero: superhero}} = socket) do
    form =
      if superhero do
        AshPhoenix.Form.for_update(superhero, :update, as: "superhero")
      else
        AshPhoenix.Form.for_create(MissionControl.Superhero, :create, as: "superhero")
      end

    assign(socket, form: to_form(form))
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"
  defp return_path("index", _superhero), do: ~p"/superheroes"
  defp return_path("show", superhero), do: ~p"/superheroes/#{superhero.id}"
end
