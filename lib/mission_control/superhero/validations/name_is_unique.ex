defmodule MissionControl.Superhero.Validations.AliasIsUnique do

  use Ash.Resource.Validation
  alias Ash.Error.Changes.InvalidAttribute


  @impl true
  def validate(changeset, _opts, _context) do
    superhero_alias = Ash.Changeset.get_attribute(changeset, :alias)

    if alias_is_unique?(superhero_alias) do
      :ok
    else
      {:error,
       InvalidAttribute.exception(
         field: :alias,
         message: "Alias '#{superhero_alias}' is already taken",
         value: superhero_alias
       )}
    end
  end

  # Simulated expensive check
  defp alias_is_unique?(_superhero_alias) do
    :timer.sleep(1000)
    true
  end
end
