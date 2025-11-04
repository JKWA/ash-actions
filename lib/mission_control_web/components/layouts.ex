defmodule MissionControlWeb.Layouts do
  use MissionControlWeb, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="px-6 py-4 border-b border-base-300 bg-base-100 text-base-content">
      <div class="flex items-center justify-between max-w-7xl mx-auto">
        <a href="/" class="text-lg font-semibold">
          Mission Control
        </a>
      </div>
    </header>

    <main class="px-6 py-10 max-w-7xl mx-auto text-base-content">
      {render_slot(@inner_block)}
    </main>

    <.flash_group flash={@flash} />
    """
  end

  attr :flash, :map, required: true
  attr :id, :string, default: "flash-group"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
    </div>
    """
  end
end
