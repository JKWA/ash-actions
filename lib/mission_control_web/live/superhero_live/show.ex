defmodule MissionControlWeb.SuperheroLive.Show do
  use MissionControlWeb, :live_view
  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Superhero {@superhero.name}
        <:subtitle>This superhero record is stored in ETS.</:subtitle>

        <:actions>
          <.button navigate={~p"/superheroes"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/superheroes/#{@superhero}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit Superhero
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@superhero.name}</:item>
        <:item title="Alias">{@superhero.alias}</:item>
        <:item title="Status">{@superhero.status}</:item>
        <:item title="Fights Won">{@superhero.fights_won}</:item>
        <:item title="Fights Lost">{@superhero.fights_lost}</:item>
        <:item title="Total Fights">{@superhero.total_fights}</:item>
        <:item title="Win Rate">
          {if @superhero.win_rate, do: "#{Float.round(@superhero.win_rate * 100, 1)}%", else: "N/A"}
        </:item>
        <:item title="Health">{@superhero.health}</:item>
        <:item title="Is Healthy?">{@superhero.is_healthy}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    superhero =
      MissionControl.Superhero
      |> Ash.get!(id)
      |> Ash.load!([:total_fights, :win_rate, :is_healthy])

    {:ok,
     socket
     |> assign(:page_title, "Show Superhero")
     |> assign(:superhero, superhero)}
  end

end
