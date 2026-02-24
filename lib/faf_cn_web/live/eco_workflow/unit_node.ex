defmodule FafCnWeb.EcoWorkflow.UnitNode do
  @moduledoc """
  Unit Node - Compact representation of a FAF unit to build.

  Displays:
  - Unit icon
  - Unit nickname (or description if no nickname)
  - Mass, Energy, Build Time (multiplied by quantity)
  - Quantity selector (default: 1)
  """
  use Phoenix.LiveComponent
  import FafCnWeb.CoreComponents

  alias FafCnWeb.FafUnitsHelpers

  @impl true
  def update(assigns, socket) do
    data = assigns.node.data
    unit = data[:unit]
    quantity = data[:quantity] || 1

    socket =
      socket
      |> assign(:node, assigns.node)
      |> assign(:id, assigns.id)
      |> assign(:unit, unit)
      |> assign(:unit_name, get_unit_display_name(unit))
      |> assign(:unit_id, unit && unit.unit_id)
      |> assign(:faction, unit && unit.faction)
      |> assign(:quantity, quantity)
      |> assign(:build_cost_mass, calculate_cost(unit, :build_cost_mass, quantity))
      |> assign(:build_cost_energy, calculate_cost(unit, :build_cost_energy, quantity))
      |> assign(:build_time, calculate_cost(unit, :build_time, quantity))
      |> assign(:finished_time, data[:finished_time])

    {:ok, socket}
  end

  # Format number with K suffix for large numbers
  defp format_number(nil), do: "0"
  defp format_number(n) when n < 1000, do: to_string(n)

  defp format_number(n) when n < 1_000_000 do
    # Format as X.XK
    value = Float.round(n / 1000, 1)
    # Remove .0 if whole number
    if value == trunc(value) do
      "#{trunc(value)}K"
    else
      "#{value}K"
    end
  end

  defp format_number(n) do
    # Format as X.XM
    value = Float.round(n / 1_000_000, 1)

    if value == trunc(value) do
      "#{trunc(value)}M"
    else
      "#{value}M"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="workflow-node-unit-compact">
      <%!-- Header with Icon and Name --%>
      <div class={[
        "workflow-node-unit-compact-header",
        @faction && FafUnitsHelpers.faction_bg_class(@faction)
      ]}>
        <%= if @unit do %>
          <div class={["unit-icon-#{@unit_id} w-5 h-5 shrink-0"]}></div>
          <span class="workflow-node-unit-name truncate" title={@unit_name}>
            {@unit_name}
          </span>
        <% else %>
          <.icon name="hero-question-mark-circle" class="w-4 h-4" />
          <span class="text-[10px]">Select</span>
        <% end %>
      </div>

      <%= if @unit do %>
        <%!-- Body with Costs and Quantity --%>
        <div class="workflow-node-unit-compact-body">
          <%!-- Edit Button - Top Right of Body --%>
          <button
            type="button"
            class="workflow-node-unit-edit-btn"
            id={"unit-edit-btn-#{@node.id}"}
            phx-hook="EditButton"
            data-event="open_unit_selector"
            data-node-id={@node.id}
            title="Change unit"
          >
            <.icon name="hero-pencil-square" class="w-3 h-3" />
          </button>
          <%!-- Resource Costs Row --%>
          <div class="workflow-node-unit-costs">
            <div class="workflow-node-unit-cost" title="Mass: #{@build_cost_mass}">
              <.icon name="hero-cube" class="w-3 h-3 text-mass" />
              <span class="text-[10px] font-medium">{format_number(@build_cost_mass)}</span>
            </div>
            <div class="workflow-node-unit-cost" title="Energy: #{@build_cost_energy}">
              <.icon name="hero-bolt" class="w-3 h-3 text-energy" />
              <span class="text-[10px] font-medium">{format_number(@build_cost_energy)}</span>
            </div>
            <div class="workflow-node-unit-cost" title="Build Time: #{@build_time}">
              <.icon name="hero-clock" class="w-3 h-3 text-build" />
              <span class="text-[10px] font-medium">{format_number(@build_time)}</span>
            </div>
          </div>

          <%!-- Quantity Selector Row --%>
          <div class="workflow-node-unit-quantity">
            <button
              class="workflow-node-unit-qty-btn"
              phx-click="decrease_quantity"
              phx-value-node-id={@node.id}
              phx-stop
              disabled={@quantity <= 1}
            >
              <.icon name="hero-minus" class="w-3 h-3" />
            </button>
            <span class="workflow-node-unit-qty-value">{@quantity}</span>
            <button
              class="workflow-node-unit-qty-btn"
              phx-click="increase_quantity"
              phx-value-node-id={@node.id}
              phx-stop
            >
              <.icon name="hero-plus" class="w-3 h-3" />
            </button>
          </div>
        </div>

        <%!-- Finished Time Badge --%>
        <%= if @finished_time do %>
          <div class="workflow-node-unit-finished-badge">
            {@finished_time}s
          </div>
        <% end %>
      <% else %>
        <%!-- Empty State --%>
        <div class="flex flex-col items-center justify-center py-3 text-base-content/50">
          <.icon name="hero-plus-circle" class="w-6 h-6 mb-1" />
          <span class="text-[9px]">Click ✏️ to select</span>
        </div>
      <% end %>
    </div>
    """
  end

  defp get_unit_display_name(nil), do: nil

  defp get_unit_display_name(unit) do
    # Prefer nickname (name field), fallback to description, then unit_id
    unit.name || unit.description || unit.unit_id
  end

  defp calculate_cost(nil, _field, _quantity), do: 0

  defp calculate_cost(unit, field, quantity) do
    value = Map.get(unit, field, 0)
    value * quantity
  end
end
