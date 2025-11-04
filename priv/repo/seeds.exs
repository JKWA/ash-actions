# Script for populating the data layer. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can use Ash actions to create data:
#
#     MissionControl.Superhero
#     |> Ash.Changeset.for_create(:create, %{name: "Superman", alias: "Clark Kent"})
#     |> Ash.create!()
#
# We recommend using the bang functions (`create!`, `update!`
# and so on) as they will fail if something goes wrong.
