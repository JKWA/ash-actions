defmodule MissionControl.Seeder do
  @moduledoc """
  Seeds initial data for the Mission Control application.
  Runs automatically on application startup.
  """

  require Logger

  def seed do
    if should_seed?() do
      Logger.info("Seeding initial data...")
      seed_superheroes()
      Logger.info("Seeding complete!")
    else
      Logger.debug("Data already exists, skipping seed.")
    end
  end

  defp should_seed? do
    Ash.read!(MissionControl.Superhero) == []
  end

  defp seed_superheroes do
    superheroes_data()
    |> Enum.each(&create_superhero/1)
  end

  defp superheroes_data do
    [
      %{name: "Clark Kent", alias: "Superman"},
      %{name: "Bruce Wayne", alias: "Batman"},
      %{name: "Diana Prince", alias: "Wonder Woman"},
      %{name: "Peter Parker", alias: "Spider-Man"},
      %{name: "Tony Stark", alias: "Iron Man"},
      %{name: "Barry Allen", alias: "The Flash"}
    ]
  end

  defp create_superhero(attrs) do
    case MissionControl.create_superhero(attrs) do
      {:ok, superhero} ->
        Logger.info("Created superhero: #{superhero.alias}")

      {:error, error} ->
        Logger.error("Failed to create superhero: #{inspect(error)}")
    end
  end
end
