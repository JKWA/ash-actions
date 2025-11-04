defmodule MissionControlWeb.PageController do
  use MissionControlWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
