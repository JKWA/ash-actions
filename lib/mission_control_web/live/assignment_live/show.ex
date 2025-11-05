defmodule MissionControlWeb.AssignmentLive.Show do
  use MissionControlWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Assignment {@assignment.id}
        <:subtitle>This is a assignment record from your database.</:subtitle>

        <:actions>
          <.button navigate={~p"/assignments"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/assignments/#{@assignment}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit Assignment
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Id">{@assignment.id}</:item>

        <:item title="Difficulty">{@assignment.difficulty}</:item>

        <:item title="Status">{@assignment.status}</:item>

        <:item title="Result">{@assignment.result}</:item>

        <:item title="Health cost">{@assignment.health_cost}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Assignment")
     |> assign(:assignment, Ash.get!(MissionControl.Assignment, id))}
  end
end
