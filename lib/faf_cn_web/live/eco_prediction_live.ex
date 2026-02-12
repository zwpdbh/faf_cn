defmodule FafCnWeb.EcoPredictionLive do
  @moduledoc """
  LiveView for Eco Prediction - Goal oriented, single-shot simulation.
  Layout matches Eco Guides: Left column (8 cols) = Initial Eco + Unit Selection, Right column (4 cols) = Selected Unit + Run + Timeline
  """
  use FafCnWeb, :live_view

  alias FafCn.Units
  on_mount {FafCnWeb.UserAuth, :mount_current_user}

  @factions ["UEF", "CYBRAN", "AEON", "SERAPHIM"]

  @impl true
  def mount(_params, _session, socket) do
    units = Units.list_units_for_eco_guides()
    units_by_faction = group_units_by_faction(units)

    {:ok, assign(socket,
      page_title: "Eco Prediction",
      factions: @factions,
      selected_faction: "UEF",
      units: units,
      units_by_faction: units_by_faction,
      
      # Left column: Initial Eco
      mass_income: "10",
      energy_income: "100",
      t1_engineers: "5",
      t2_engineers: "0",
      t3_engineers: "0",
      mass_storage: "650",
      mass_storage_max: "650",
      energy_storage: "2500",
      energy_storage_max: "2500",
      
      # Left column: Unit Selection
      selected_unit: nil,
      goal_quantity: 1,
      
      # Right column: Results
      show_results: false,
      simulation_result: nil
    )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <%!-- Header --%>
        <div class="mb-6">
          <h1 class="text-3xl font-bold text-gray-900">Eco Prediction</h1>
          <p class="mt-2 text-gray-600">
            Calculate how long it takes to afford your target units.
          </p>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
          <%!-- Left Column (8 cols): Initial Eco + Unit Selection --%>
          <div class="lg:col-span-8 space-y-6">
            <%!-- 1. Set Initial Eco --%>
            <.initial_eco_card 
              mass_income={@mass_income}
              energy_income={@energy_income}
              t1_engineers={@t1_engineers}
              t2_engineers={@t2_engineers}
              t3_engineers={@t3_engineers}
              mass_storage={@mass_storage}
              mass_storage_max={@mass_storage_max}
              energy_storage={@energy_storage}
              energy_storage_max={@energy_storage_max}
            />

            <%!-- 2. Select Units (with faction tabs inside) --%>
            <.unit_selection_card
              factions={@factions}
              units_by_faction={@units_by_faction}
              selected_faction={@selected_faction}
              selected_unit={@selected_unit}
            />
          </div>

          <%!-- Right Column (4 cols): Selected Unit + Run + Timeline --%>
          <div class="lg:col-span-4 space-y-4">
            <.goal_panel
              selected_unit={@selected_unit}
              goal_quantity={@goal_quantity}
              can_run={@selected_unit != nil}
            />

            <%= if @show_results do %>
              <.timeline_card result={@simulation_result} />
            <% end %>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # Components

  def faction_tabs(assigns) do
    ~H"""
    <div class="border-b border-gray-200">
      <nav class="-mb-px flex space-x-8" aria-label="Tabs">
        <%= for faction <- @factions do %>
          <% is_active = @selected_faction == faction
          active_classes =
            case faction do
              "UEF" -> if is_active, do: "border-blue-500 text-blue-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
              "CYBRAN" -> if is_active, do: "border-red-500 text-red-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
              "AEON" -> if is_active, do: "border-emerald-500 text-emerald-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
              "SERAPHIM" -> if is_active, do: "border-violet-500 text-violet-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
            end
          %>
          <button
            phx-click="select_faction"
            phx-value-faction={faction}
            class={["whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm transition-colors", active_classes]}
          >
            {faction}
          </button>
        <% end %>
      </nav>
    </div>
    """
  end

  def initial_eco_card(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
      <h2 class="text-lg font-semibold text-gray-900 mb-4">1. Set Initial Eco</h2>

      <div class="space-y-6">
        <%!-- Mass Group --%>
        <div class="bg-blue-50 rounded-lg p-4 border border-blue-100">
          <h3 class="text-sm font-semibold text-blue-900 mb-3 flex items-center gap-2">
            <.icon name="hero-cube" class="w-4 h-4" /> Mass
          </h3>
          <div class="space-y-3">
            <div>
              <label class="block text-xs font-medium text-blue-700 mb-1">Income / second</label>
              <input
                type="number"
                value={@mass_income}
                phx-change="update_mass_income"
                class="w-full px-3 py-2 border border-blue-200 rounded-md focus:ring-blue-500 focus:border-blue-500 bg-white"
              />
            </div>
            <div>
              <label class="block text-xs font-medium text-blue-700 mb-1">Storage (Current / Max)</label>
              <div class="flex gap-2">
                <input
                  type="number"
                  value={@mass_storage}
                  phx-change="update_mass_storage"
                  placeholder="Current"
                  class="flex-1 px-3 py-2 border border-blue-200 rounded-md bg-white"
                />
                <span class="self-center text-blue-400">/</span>
                <input
                  type="number"
                  value={@mass_storage_max}
                  phx-change="update_mass_max"
                  placeholder="Max"
                  class="flex-1 px-3 py-2 border border-blue-200 rounded-md bg-white"
                />
              </div>
            </div>
          </div>
        </div>

        <%!-- Energy Group --%>
        <div class="bg-yellow-50 rounded-lg p-4 border border-yellow-100">
          <h3 class="text-sm font-semibold text-yellow-900 mb-3 flex items-center gap-2">
            <.icon name="hero-bolt" class="w-4 h-4" /> Energy
          </h3>
          <div class="space-y-3">
            <div>
              <label class="block text-xs font-medium text-yellow-700 mb-1">Income / second</label>
              <input
                type="number"
                value={@energy_income}
                phx-change="update_energy_income"
                class="w-full px-3 py-2 border border-yellow-200 rounded-md focus:ring-yellow-500 focus:border-yellow-500 bg-white"
              />
            </div>
            <div>
              <label class="block text-xs font-medium text-yellow-700 mb-1">Storage (Current / Max)</label>
              <div class="flex gap-2">
                <input
                  type="number"
                  value={@energy_storage}
                  phx-change="update_energy_storage"
                  placeholder="Current"
                  class="flex-1 px-3 py-2 border border-yellow-200 rounded-md bg-white"
                />
                <span class="self-center text-yellow-400">/</span>
                <input
                  type="number"
                  value={@energy_storage_max}
                  phx-change="update_energy_max"
                  placeholder="Max"
                  class="flex-1 px-3 py-2 border border-yellow-200 rounded-md bg-white"
                />
              </div>
            </div>
          </div>
        </div>

        <%!-- Build Power Group --%>
        <div class="bg-purple-50 rounded-lg p-4 border border-purple-100">
          <h3 class="text-sm font-semibold text-purple-900 mb-3 flex items-center gap-2">
            <.icon name="hero-wrench" class="w-4 h-4" /> Build Power (Engineers)
          </h3>
          <div class="grid grid-cols-3 gap-3">
            <div>
              <label class="block text-xs font-medium text-purple-700 mb-1">T1</label>
              <input
                type="number"
                value={@t1_engineers}
                phx-change="update_t1_eng"
                class="w-full px-3 py-2 border border-purple-200 rounded-md bg-white"
              />
            </div>
            <div>
              <label class="block text-xs font-medium text-purple-700 mb-1">T2</label>
              <input
                type="number"
                value={@t2_engineers}
                phx-change="update_t2_eng"
                class="w-full px-3 py-2 border border-purple-200 rounded-md bg-white"
              />
            </div>
            <div>
              <label class="block text-xs font-medium text-purple-700 mb-1">T3</label>
              <input
                type="number"
                value={@t3_engineers}
                phx-change="update_t3_eng"
                class="w-full px-3 py-2 border border-purple-200 rounded-md bg-white"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def unit_selection_card(assigns) do
    units = assigns.units_by_faction[assigns.selected_faction] || []
    assigns = assign(assigns, :units, units)
    
    ~H"""
    <div
      class="rounded-lg shadow-sm border border-gray-200 p-4"
      style="background-image: url('/images/units/background.jpg'); background-size: cover; background-position: center;"
    >
      <%!-- Header with Title and Faction Tabs --%>
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-4 gap-3">
        <h2 class="text-lg font-semibold text-white drop-shadow-md">2. Select Units</h2>
        
        <%!-- Faction Tabs inside the card --%>
        <div class="flex space-x-1 bg-black/30 rounded-lg p-1">
          <%= for faction <- @factions do %>
            <% is_active = @selected_faction == faction
            active_classes =
              case faction do
                "UEF" -> if is_active, do: "bg-blue-600 text-white", else: "text-blue-200 hover:bg-blue-900/50"
                "CYBRAN" -> if is_active, do: "bg-red-600 text-white", else: "text-red-200 hover:bg-red-900/50"
                "AEON" -> if is_active, do: "bg-emerald-600 text-white", else: "text-emerald-200 hover:bg-emerald-900/50"
                "SERAPHIM" -> if is_active, do: "bg-violet-600 text-white", else: "text-violet-200 hover:bg-violet-900/50"
              end
            %>
            <button
              phx-click="select_faction"
              phx-value-faction={faction}
              class={["px-3 py-1 rounded text-xs font-medium transition-colors", active_classes]}
            >
              {faction}
            </button>
          <% end %>
        </div>
      </div>

      <%!-- Unit Grid --%>
      <div class="grid grid-cols-4 sm:grid-cols-6 md:grid-cols-8 gap-3">
        <%= for unit <- @units do %>
          <% is_selected = @selected_unit && @selected_unit.unit_id == unit.unit_id
          border_class =
            if is_selected,
              do: "ring-2 ring-indigo-500 ring-offset-1",
              else: "hover:ring-2 hover:ring-gray-300 hover:ring-offset-1 cursor-pointer"
          %>
          <button
            type="button"
            phx-click="select_unit"
            phx-value-unit-id={unit.unit_id}
            class={[
              "group relative aspect-square rounded-lg p-1 transition-all duration-150 flex flex-col items-center justify-center text-center overflow-hidden",
              unit_faction_bg_class(unit.faction),
              border_class
            ]}
            title={"#{unit.unit_id} - #{unit.description || unit.name || "Unknown"}"}
          >
            <div class={["unit-icon-#{unit.unit_id} w-12 h-12 shrink-0"]}></div>
            <%= if is_selected do %>
              <span class="absolute -top-1 -right-1 w-5 h-5 bg-indigo-500 rounded-full flex items-center justify-center z-10">
                <.icon name="hero-check" class="w-3 h-3 text-white" />
              </span>
            <% end %>
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  def goal_panel(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
      <%= if @selected_unit do %>
        <%!-- Selected Unit Display --%>
        <div class="text-center mb-4">
          <div class={["w-16 h-16 rounded-lg mx-auto mb-2", unit_faction_bg_class(@selected_unit.faction)]}>
            <div class={"unit-icon-#{@selected_unit.unit_id} w-full h-full"} />
          </div>
          <h3 class="font-semibold text-gray-900">{@selected_unit.name}</h3>
          <p class="text-sm text-gray-500">{@selected_unit.unit_id}</p>
          <p class="text-sm text-gray-600 mt-1">
            {@selected_unit.build_cost_mass}M / {@selected_unit.build_cost_energy}E
          </p>
        </div>

        <%!-- Quantity Input --%>
        <div class="mb-4">
          <label class="block text-sm font-medium text-gray-700 mb-1">Quantity</label>
          <input
            type="number"
            min="1"
            value={@goal_quantity}
            phx-change="update_quantity"
            class="w-full px-3 py-2 border border-gray-300 rounded-md text-center text-lg font-semibold"
          />
          <p class="text-sm text-indigo-600 font-medium mt-2 text-center">
            Total: {@goal_quantity * @selected_unit.build_cost_mass}M / {@goal_quantity * @selected_unit.build_cost_energy}E
          </p>
        </div>

        <%!-- Run Button --%>
        <button
          phx-click="run_simulation"
          disabled={!@can_run}
          class="w-full py-3 px-4 bg-indigo-600 text-white font-medium rounded-lg hover:bg-indigo-700 transition-colors"
        >
          🚀 Run Simulation
        </button>
      <% else %>
        <%!-- Empty State --%>
        <div class="text-center py-8 text-gray-400">
          <.icon name="hero-cube" class="w-12 h-12 mx-auto mb-3 opacity-50" />
          <p class="text-sm">Select a unit from the grid</p>
          <p class="text-xs mt-1">to see prediction results</p>
        </div>
      <% end %>
    </div>
    """
  end

  def timeline_card(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
      <h3 class="font-semibold text-gray-900 mb-4">Timeline</h3>
      
      <div class="relative pl-6 space-y-4">
        <%!-- Vertical line --%>
        <div class="absolute left-2 top-2 bottom-2 w-0.5 bg-gray-300"></div>
        
        <%= for {milestone, idx} <- Enum.with_index(@result.milestones) do %>
          <div class="relative">
            <%!-- Dot --%>
            <div class={[
              "absolute -left-4 w-4 h-4 rounded-full border-2",
              if(idx == length(@result.milestones) - 1, 
                do: "bg-green-500 border-green-500", 
                else: "bg-white border-indigo-500")
            ]}></div>
            
            <div class="flex items-center gap-3">
              <span class="text-sm font-mono text-gray-500 w-14">
                <%= format_time(milestone.time) %>
              </span>
              <div class={[
                "flex-1 p-2 rounded text-sm",
                if(idx == length(@result.milestones) - 1, do: "bg-green-100 font-medium", else: "bg-gray-50")
              ]}>
                {milestone.label}
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # Event Handlers

  @impl true
  def handle_event("select_faction", %{"faction" => faction}, socket) do
    {:noreply, assign(socket, :selected_faction, faction)}
  end

  @impl true
  def handle_event("select_unit", %{"unit-id" => unit_id}, socket) do
    unit = Enum.find(socket.assigns.units, &(&1.unit_id == unit_id))
    {:noreply, assign(socket, :selected_unit, unit)}
  end

  @impl true
  def handle_event("update_quantity", %{"value" => qty}, socket) do
    qty = String.to_integer(qty) |> max(1)
    {:noreply, assign(socket, :goal_quantity, qty)}
  end

  @impl true
  def handle_event("update_" <> field, %{"value" => value}, socket) do
    field_atom = String.to_atom(field)
    {:noreply, assign(socket, field_atom, value)}
  end

  @impl true
  def handle_event("run_simulation", _params, socket) do
    # Generate dummy result for UI prototype
    result = %{
      completion_time: 347,
      goal_quantity: socket.assigns.goal_quantity,
      unit_name: socket.assigns.selected_unit.name,
      milestones: [
        %{time: 0, label: "Start"},
        %{time: 120, label: "Mass storage full"},
        %{time: 234, label: "Energy threshold reached"},
        %{time: 347, label: "Goal Complete"}
      ]
    }
    
    {:noreply, socket
      |> assign(:show_results, true)
      |> assign(:simulation_result, result)}
  end

  # Helpers

  defp group_units_by_faction(units) do
    units
    |> Enum.group_by(& &1.faction)
    |> Enum.map(fn {faction, faction_units} ->
      {faction, Enum.sort_by(faction_units, & &1.unit_id)}
    end)
    |> Enum.into(%{})
  end

  defp unit_faction_bg_class(faction) do
    case faction do
      "UEF" -> "unit-bg-uef"
      "CYBRAN" -> "unit-bg-cybran"
      "AEON" -> "unit-bg-aeon"
      "SERAPHIM" -> "unit-bg-seraphim"
      _ -> "bg-gray-100"
    end
  end

  defp format_time(seconds) do
    mins = div(seconds, 60)
    secs = rem(seconds, 60)
    "#{mins}:#{String.pad_leading("#{secs}", 2, "0")}"
  end
end
