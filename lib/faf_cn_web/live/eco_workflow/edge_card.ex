defmodule FafCnWeb.EcoWorkflow.EdgeCard do
  @moduledoc """
  Edge Card Component - Displays eco status when hovering over edges.

  During simulation:
  - Hover shows simplified tooltip with mass/energy drain only
  - Double-click opens modal with full eco statistics
  - Edge cannot be deleted (deletable: false)
  """
  use Phoenix.LiveComponent
  import FafCnWeb.CoreComponents

  @impl true
  def update(assigns, socket) do
    edge_data = assigns.edge.data || %{}
    simulation_run = edge_data[:simulation_run] || false

    # Calculate drain (negative values indicate consumption)
    mass_drain = edge_data[:mass_per_sec] || 0
    energy_drain = edge_data[:energy_per_sec] || 0

    socket =
      socket
      |> assign(:edge, assigns.edge)
      |> assign(:id, assigns.id)
      |> assign(:mass_in_storage, edge_data[:mass_in_storage] || 650)
      |> assign(:energy_in_storage, edge_data[:energy_in_storage] || 5000)
      |> assign(:mass_per_sec, mass_drain)
      |> assign(:energy_per_sec, energy_drain)
      |> assign(:mass_drain, mass_drain)
      |> assign(:energy_drain, energy_drain)
      |> assign(:build_power, edge_data[:build_power] || 10)
      |> assign(:elapsed_time, edge_data[:elapsed_time] || 0)
      |> assign(:simulation_run, simulation_run)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @simulation_run do %>
      <%!-- Simplified tooltip for simulation mode - only mass/energy drain --%>
      <div class="workflow-edge-tooltip" id={"edge-tooltip-#{@edge.id}"}>
        <div class="workflow-edge-tooltip-row">
          <.icon name="hero-cube" class="w-3 h-3 text-mass" />
          <span class="text-mass font-medium">-{format_drain(@mass_drain)}/s</span>
        </div>
        <div class="workflow-edge-tooltip-row">
          <.icon name="hero-bolt" class="w-3 h-3 text-energy" />
          <span class="text-energy font-medium">-{format_drain(@energy_drain)}/s</span>
        </div>
        <div class="workflow-edge-tooltip-hint">
          <.icon name="hero-information-circle" class="w-3 h-3" />
          <span>Double-click for details</span>
        </div>
      </div>
    <% else %>
      <%!-- Full eco status card for normal mode --%>
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
    <% end %>
    """
  end

  defp format_drain(value) when is_float(value) do
    # Format with 1 decimal place if needed
    if trunc(value) == value do
      "#{trunc(value)}"
    else
      "#{Float.round(value, 1)}"
    end
  end

  defp format_drain(value) when is_integer(value), do: "#{value}"
  defp format_drain(_), do: "0"
end
