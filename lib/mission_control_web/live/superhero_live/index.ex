defmodule MissionControlWeb.SuperheroLive.Index do
  use MissionControlWeb, :live_view
  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Superheroes
        <:actions>
          <.button variant="primary" navigate={~p"/superheroes/new"}>
            <.icon name="hero-plus" /> New Superhero
          </.button>
        </:actions>
      </.header>

      <.table
        id="superheroes"
        rows={@streams.superheroes}
        row_click={fn {_id, superhero} -> JS.navigate(~p"/superheroes/#{superhero}") end}
      >
        <:col :let={{_id, superhero}} label="Name">{superhero.name}</:col>
        <:col :let={{_id, superhero}} label="Alias">{superhero.alias}</:col>
        <:col :let={{_id, superhero}} label="Health">{superhero.health}</:col>
        <:col :let={{_id, superhero}} label="Status">{superhero.status}</:col>
        <:col :let={{_id, superhero}} label="Total Fights">{superhero.total_fights}</:col>
        <:col :let={{_id, superhero}} label="Win Rate">
          {if superhero.win_rate, do: "#{Float.round(superhero.win_rate * 100, 1)}%", else: "N/A"}
        </:col>

        <:action :let={{_id, superhero}}>
          <div class="sr-only">
            <.link navigate={~p"/superheroes/#{superhero}"}>Show</.link>
          </div>

          <.link navigate={~p"/superheroes/#{superhero}/edit"}>Edit</.link>
        </:action>

        <:action :let={{_id, superhero}}>
          <.link phx-click={JS.push("assign", value: %{id: superhero.id})}>
            Assign
          </.link>
        </:action>

        <:action :let={{id, superhero}}>
          <.link
            phx-click={JS.push("delete", value: %{id: superhero.id}) |> hide("##{id}")}
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
    superheroes =
      MissionControl.Superhero
      |> Ash.read!()
      |> Ash.load!([:total_fights, :win_rate, :is_healthy])

    {:ok,
     socket
     |> assign(:page_title, "Listing Superheroes")
     |> stream(:superheroes, superheroes)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    superhero = Ash.get!(MissionControl.Superhero, id)
    Ash.destroy!(superhero)
    {:noreply, stream_delete(socket, :superheroes, superhero)}
  end

  @impl true
  def handle_event("assign", %{"id" => id}, socket) do
    superhero = Ash.get!(MissionControl.Superhero, id)

    case MissionControl.create_assignment(%{
           superhero_id: superhero.id,
           name: superhero.alias <> " Assignment",
           difficulty: 1
         }) do
      {:ok, _assignment} ->
        {:noreply, put_flash(socket, :info, "Superhero sent on assignment!")}

      {:error, %Ash.Error.Invalid{errors: errors} = error} ->
        Logger.error("Assignment creation failed: #{inspect(error, pretty: true)}")

        # Extract first message
        message =
          case errors do
            [%{message: msg} | _] -> msg
            _ -> "An unknown error occurred."
          end

        {:noreply, put_flash(socket, :error, message)}

      {:error, error} ->
        Logger.error("Assignment creation failed: #{inspect(error, pretty: true)}")
        {:noreply, put_flash(socket, :error, Exception.message(error))}
    end
  end
end
