defmodule FafCnWeb.EcoWorkflow.EdgeCard do
  @moduledoc """
  Edge Card Component - Displays eco status when hovering over edges.

  Shows:
  - Current mass/energy storage
  - Mass/energy income rates
  - Build power
  - Time elapsed at this point in the workflow
  """
  use Phoenix.LiveComponent
  import FafCnWeb.CoreComponents

  @impl true
  def update(assigns, socket) do
    edge_data = assigns.edge.data || %{}

    socket =
      socket
      |> assign(:edge, assigns.edge)
      |> assign(:id, assigns.id)
      |> assign(:mass_in_storage, edge_data[:mass_in_storage] || 650)
      |> assign(:energy_in_storage, edge_data[:energy_in_storage] || 5000)
      |> assign(:mass_per_sec, edge_data[:mass_per_sec] || 1.0)
      |> assign(:energy_per_sec, edge_data[:energy_per_sec] || 20.0)
      |> assign(:build_power, edge_data[:build_power] || 10)
      |> assign(:elapsed_time, edge_data[:elapsed_time] || 0)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="workflow-edge-card">
      <div class="workflow-edge-card-header">
        <.icon name="hero-arrow-path" class="w-3 h-3" />
        <span>Eco Status</span>
        <%= if @elapsed_time > 0 do %>
          <span class="workflow-edge-card-time">{@elapsed_time}s</span>
        <% end %>
      </div>
      <div class="workflow-edge-card-body">
        <%!-- Storage Row --%>
        <div class="workflow-edge-card-row">
          <div class="workflow-edge-card-stat">
            <.icon name="hero-cube" class="w-3 h-3 text-mass" />
            <span class="workflow-edge-card-value text-mass">{@mass_in_storage}</span>
          </div>
          <div class="workflow-edge-card-stat">
            <.icon name="hero-bolt" class="w-3 h-3 text-energy" />
            <span class="workflow-edge-card-value text-energy">{@energy_in_storage}</span>
          </div>
        </div>

        <%!-- Income Row --%>
        <div class="workflow-edge-card-row">
          <div class="workflow-edge-card-stat">
            <.icon name="hero-arrow-trending-up" class="w-3 h-3 text-mass" />
            <span class="text-xs text-base-content/60">+{@mass_per_sec}/s</span>
          </div>
          <div class="workflow-edge-card-stat">
            <.icon name="hero-arrow-trending-down" class="w-3 h-3 text-energy" />
            <span class="text-xs text-base-content/60">+{@energy_per_sec}/s</span>
          </div>
        </div>

        <%!-- Build Power --%>
        <div class="workflow-edge-card-divider"></div>
        <div class="workflow-edge-card-row">
          <div class="workflow-edge-card-stat">
            <.icon name="hero-wrench" class="w-3 h-3 text-build" />
            <span class="text-xs font-medium">{@build_power} BP</span>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
