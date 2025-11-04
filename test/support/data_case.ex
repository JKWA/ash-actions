defmodule MissionControl.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Since this app uses Ash with ETS data layer, data is stored
  in memory and automatically cleaned up between tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import MissionControl.DataCase
    end
  end

  setup _tags do
    :ok
  end
end
