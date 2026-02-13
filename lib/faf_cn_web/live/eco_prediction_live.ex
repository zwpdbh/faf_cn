defmodule FafCnWeb.EcoPredictionLive do
  @moduledoc """
  LiveView for Eco Prediction - Goal oriented, single-shot simulation.
  Layout matches Eco Guides: Left column (8 cols) = Initial Eco + Unit Selection, Right column (4 cols) = Selected Unit + Run + Timeline
  """
  use FafCnWeb, :live_view

  alias FafCn.Units
  on_mount {FafCnWeb.UserAuth, :mount_current_user}

  @factions ["UEF", "CYBRAN", "AEON", "SERAPHIM"]

  @filters [
    %{key: "ENGINEER", label: "Engineer", category: "ENGINEER", group: :usage},
    %{key: "STRUCTURE", label: "Structure", category: "STRUCTURE", group: :usage},
    %{key: "LAND", label: "Land", category: "LAND", group: :usage},
    %{key: "AIR", label: "Air", category: "AIR", group: :usage},
    %{key: "NAVAL", label: "Naval", category: "NAVAL", group: :usage},
    %{key: "TECH1", label: "T1", category: "TECH1", group: :tech},
    %{key: "TECH2", label: "T2", category: "TECH2", group: :tech},
    %{key: "TECH3", label: "T3", category: "TECH3", group: :tech},
    %{key: "EXPERIMENTAL", label: "EXP", category: "EXPERIMENTAL", group: :tech}
  ]

  @usage_filters ["ENGINEER", "STRUCTURE", "LAND", "AIR", "NAVAL"]
  @tech_filters ["TECH1", "TECH2", "TECH3", "EXPERIMENTAL"]

  @impl true
  def mount(_params, _session, socket) do
    units = Units.list_units_for_eco_guides()
    units_by_faction = group_units_by_faction(units)

    {:ok,
     assign(socket,
       page_title: "Eco Prediction",
       factions: @factions,
       filters: @filters,
       active_filters: ["EXPERIMENTAL"],
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
       simulation_result: nil,
       chart_view: "mass"
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

        <%!-- Faction Tabs (at top like Eco Guides) --%>
        <div class="mb-6">
          <.faction_tabs factions={@factions} selected_faction={@selected_faction} />
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

            <%!-- 2. Select Units (with filters like Eco Guides) --%>
            <.unit_selection_card
              units_by_faction={@units_by_faction}
              selected_faction={@selected_faction}
              selected_unit={@selected_unit}
              filters={@filters}
              active_filters={@active_filters}
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

        <%!-- Full Width Chart (spans both columns) --%>
        <%= if @show_results do %>
          <.eco_chart_card
            result={@simulation_result}
            mass_income={@mass_income}
            energy_income={@energy_income}
            chart_view={@chart_view}
          />
        <% end %>
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
              "UEF" ->
                if is_active,
                  do: "border-blue-500 text-blue-600",
                  else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"

              "CYBRAN" ->
                if is_active,
                  do: "border-red-500 text-red-600",
                  else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"

              "AEON" ->
                if is_active,
                  do: "border-emerald-500 text-emerald-600",
                  else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"

              "SERAPHIM" ->
                if is_active,
                  do: "border-violet-500 text-violet-600",
                  else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
            end %>
          <button
            phx-click="select_faction"
            phx-value-faction={faction}
            class={[
              "whitespace-nowrap py-2 px-1 border-b-2 font-medium text-sm transition-colors",
              active_classes
            ]}
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
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-3">
      <h2 class="text-base font-semibold text-gray-900 mb-2">1. Set Initial Eco</h2>

      <div class="space-y-2">
        <%!-- Mass & Energy in 2 columns --%>
        <div class="grid grid-cols-2 gap-2">
          <%!-- Mass Group --%>
          <div class="bg-blue-50 rounded p-2 border border-blue-100">
            <h3 class="text-xs font-semibold text-blue-900 mb-1 flex items-center gap-1">
              <.icon name="hero-cube" class="w-3 h-3" /> Mass
            </h3>
            <div class="space-y-1">
              <div>
                <label class="block text-[10px] font-medium text-blue-700 mb-0.5">Income/s</label>
                <input
                  type="number"
                  value={@mass_income}
                  phx-change="update_mass_income"
                  class="w-full px-2 py-1 text-sm border border-blue-200 rounded focus:ring-blue-500 focus:border-blue-500 bg-white"
                />
              </div>
              <div>
                <label class="block text-[10px] font-medium text-blue-700 mb-0.5">Storage</label>
                <div class="flex gap-1">
                  <input
                    type="number"
                    value={@mass_storage}
                    phx-change="update_mass_storage"
                    placeholder="Cur"
                    class="flex-1 px-1.5 py-1 text-sm border border-blue-200 rounded bg-white"
                  />
                  <span class="self-center text-blue-400 text-xs">/</span>
                  <input
                    type="number"
                    value={@mass_storage_max}
                    phx-change="update_mass_max"
                    placeholder="Max"
                    class="flex-1 px-1.5 py-1 text-sm border border-blue-200 rounded bg-white"
                  />
                </div>
              </div>
            </div>
          </div>

          <%!-- Energy Group --%>
          <div class="bg-yellow-50 rounded p-2 border border-yellow-100">
            <h3 class="text-xs font-semibold text-yellow-900 mb-1 flex items-center gap-1">
              <.icon name="hero-bolt" class="w-3 h-3" /> Energy
            </h3>
            <div class="space-y-1">
              <div>
                <label class="block text-[10px] font-medium text-yellow-700 mb-0.5">Income/s</label>
                <input
                  type="number"
                  value={@energy_income}
                  phx-change="update_energy_income"
                  class="w-full px-2 py-1 text-sm border border-yellow-200 rounded focus:ring-yellow-500 focus:border-yellow-500 bg-white"
                />
              </div>
              <div>
                <label class="block text-[10px] font-medium text-yellow-700 mb-0.5">Storage</label>
                <div class="flex gap-1">
                  <input
                    type="number"
                    value={@energy_storage}
                    phx-change="update_energy_storage"
                    placeholder="Cur"
                    class="flex-1 px-1.5 py-1 text-sm border border-yellow-200 rounded bg-white"
                  />
                  <span class="self-center text-yellow-400 text-xs">/</span>
                  <input
                    type="number"
                    value={@energy_storage_max}
                    phx-change="update_energy_max"
                    placeholder="Max"
                    class="flex-1 px-1.5 py-1 text-sm border border-yellow-200 rounded bg-white"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>

        <%!-- Build Power Group --%>
        <div class="bg-purple-50 rounded p-2 border border-purple-100">
          <h3 class="text-xs font-semibold text-purple-900 mb-1 flex items-center gap-1">
            <.icon name="hero-wrench" class="w-3 h-3" /> Engineers
          </h3>
          <div class="grid grid-cols-3 gap-2">
            <div>
              <label class="block text-[10px] font-medium text-purple-700 mb-0.5">T1</label>
              <input
                type="number"
                value={@t1_engineers}
                phx-change="update_t1_eng"
                class="w-full px-2 py-1 text-sm border border-purple-200 rounded bg-white"
              />
            </div>
            <div>
              <label class="block text-[10px] font-medium text-purple-700 mb-0.5">T2</label>
              <input
                type="number"
                value={@t2_engineers}
                phx-change="update_t2_eng"
                class="w-full px-2 py-1 text-sm border border-purple-200 rounded bg-white"
              />
            </div>
            <div>
              <label class="block text-[10px] font-medium text-purple-700 mb-0.5">T3</label>
              <input
                type="number"
                value={@t3_engineers}
                phx-change="update_t3_eng"
                class="w-full px-2 py-1 text-sm border border-purple-200 rounded bg-white"
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
    filtered_units = apply_filters(units, assigns.active_filters)
    assigns = assign(assigns, :filtered_units, filtered_units)

    ~H"""
    <div
      class="rounded-lg shadow-sm border border-gray-200 p-4"
      style="background-image: url('/images/units/background.jpg'); background-size: cover; background-position: center;"
    >
      <%!-- Header with Title --%>
      <div class="flex items-center justify-between mb-3">
        <h2 class="text-lg font-semibold text-white drop-shadow-md">2. Select Units</h2>
      </div>

      <%!-- Filter Bar (like Eco Guides) --%>
      <.filter_bar filters={@filters} active_filters={@active_filters} />

      <%!-- Unit Grid --%>
      <div class="grid grid-cols-4 sm:grid-cols-6 md:grid-cols-8 gap-3">
        <%= for unit <- @filtered_units do %>
          <% is_selected = @selected_unit && @selected_unit.unit_id == unit.unit_id

          border_class =
            if is_selected,
              do: "ring-2 ring-indigo-500 ring-offset-1",
              else: "hover:ring-2 hover:ring-gray-300 hover:ring-offset-1 cursor-pointer" %>
          <button
            type="button"
            phx-click="select_unit"
            phx-value-unit-id={unit.unit_id}
            class={[
              "group relative aspect-square rounded-lg p-1 transition-all duration-150 flex flex-col items-center justify-center text-center overflow-hidden",
              unit_faction_bg_class(unit.faction),
              border_class
            ]}
            title={"#{format_unit_display_name(unit)}: #{unit.description || "No description"}"}
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

      <%= if @filtered_units == [] do %>
        <div class="text-center py-8 text-white/70">
          <p class="text-sm">No units match the selected filters</p>
        </div>
      <% end %>
    </div>
    """
  end

  def goal_panel(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
      <%= if @selected_unit do %>
        <%!-- Selected Unit Display --%>
        <div class="text-center mb-4">
          <div class={[
            "w-16 h-16 rounded-lg mx-auto mb-2",
            unit_faction_bg_class(@selected_unit.faction)
          ]}>
            <div class={"unit-icon-#{@selected_unit.unit_id} w-full h-full"} />
          </div>
          <h3 class="font-semibold text-gray-900">
            {format_unit_display_name(@selected_unit)}
          </h3>

          <%!-- Unit Stats Cards --%>
          <div class="grid grid-cols-3 gap-2 mt-3">
            <div class="text-center p-2 bg-blue-50 rounded-lg border border-blue-100">
              <div class="text-[10px] text-blue-500 uppercase tracking-wide">Mass</div>
              <div class="text-sm font-bold text-blue-700">
                {@selected_unit.build_cost_mass}
              </div>
            </div>
            <div class="text-center p-2 bg-yellow-50 rounded-lg border border-yellow-100">
              <div class="text-[10px] text-yellow-600 uppercase tracking-wide">Energy</div>
              <div class="text-sm font-bold text-yellow-700">
                {@selected_unit.build_cost_energy}
              </div>
            </div>
            <div class="text-center p-2 bg-purple-50 rounded-lg border border-purple-100">
              <div class="text-[10px] text-purple-500 uppercase tracking-wide">Build Time</div>
              <div class="text-sm font-bold text-purple-700">
                {@selected_unit.build_time}
              </div>
            </div>
          </div>
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
            Total: {@goal_quantity * @selected_unit.build_cost_mass}M / {@goal_quantity *
              @selected_unit.build_cost_energy}E
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
                else: "bg-white border-indigo-500"
              )
            ]}>
            </div>

            <div class="flex items-center gap-3">
              <span class="text-sm font-mono text-gray-500 w-14">
                {format_time(milestone.time)}
              </span>
              <div class={[
                "flex-1 p-2 rounded text-sm",
                if(idx == length(@result.milestones) - 1,
                  do: "bg-green-100 font-medium",
                  else: "bg-gray-50"
                )
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

  def filter_bar(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-2 mb-3">
      <%= for filter <- @filters do %>
        <% is_active = filter.key in @active_filters %>
        <button
          phx-click="toggle_filter"
          phx-value-filter={filter.key}
          class={[
            "px-3 py-1.5 rounded text-sm font-medium transition-all",
            if is_active do
              "bg-indigo-500 text-white shadow-md"
            else
              "bg-white/90 text-gray-700 hover:bg-white hover:shadow"
            end
          ]}
        >
          {filter.label}
        </button>
      <% end %>
      <%= if length(@active_filters) > 0 do %>
        <button
          phx-click="clear_filters"
          class="px-3 py-1.5 rounded text-sm font-medium bg-gray-500/50 text-white hover:bg-gray-500/70 transition-all"
        >
          Clear All
        </button>
      <% end %>
    </div>
    """
  end

  def eco_chart_card(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mt-6">
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-gray-900">Resource Accumulation Over Time</h3>
        <div class="text-sm text-gray-500">
          Time to goal:
          <span class="font-medium text-indigo-600">{format_time(@result.completion_time)}</span>
        </div>
      </div>

      <%!-- View Toggle --%>
      <div class="flex gap-2 mb-4">
        <button
          phx-click="set_chart_view"
          phx-value-view="mass"
          class={[
            "flex-1 py-2 px-4 rounded-lg text-sm font-medium transition-colors flex items-center justify-center gap-2",
            if(@chart_view == "mass",
              do: "bg-blue-500 text-white",
              else: "bg-gray-100 text-gray-600 hover:bg-gray-200"
            )
          ]}
        >
          <span class="w-2 h-2 rounded-full bg-white"></span> Mass ({@mass_income}/s)
        </button>
        <button
          phx-click="set_chart_view"
          phx-value-view="energy"
          class={[
            "flex-1 py-2 px-4 rounded-lg text-sm font-medium transition-colors flex items-center justify-center gap-2",
            if(@chart_view == "energy",
              do: "bg-yellow-500 text-white",
              else: "bg-gray-100 text-gray-600 hover:bg-gray-200"
            )
          ]}
        >
          <span class="w-2 h-2 rounded-full bg-white"></span> Energy ({@energy_income}/s)
        </button>
      </div>

      <%!-- Chart Container --%>
      <div
        id={"eco-chart-#{@chart_view}-#{@result.completion_time}"}
        phx-hook="EcoChart"
        data-mass-income={@mass_income}
        data-energy-income={@energy_income}
        data-completion-time={@result.completion_time}
        data-goal-mass={@result.goal_mass}
        data-goal-energy={@result.goal_energy}
        data-view={@chart_view}
        class="w-full h-80 bg-gray-50 rounded-lg border border-gray-200"
      >
        <%!-- Fallback content --%>
        <div class="flex items-center justify-center h-full text-gray-400">
          <div class="text-center">
            <.icon name="hero-chart-bar" class="w-12 h-12 mx-auto mb-2 opacity-50" />
            <p class="text-sm">Loading chart...</p>
          </div>
        </div>
      </div>

      <%!-- Legend --%>
      <div class="flex justify-center mt-4">
        <%= if @chart_view == "mass" do %>
          <div class="flex items-center gap-2">
            <span class="w-3 h-3 rounded-full bg-blue-500"></span>
            <span class="text-sm text-gray-600">Accumulated Mass</span>
            <span class="text-xs text-gray-400 ml-1">Goal: {@result.goal_mass}M</span>
          </div>
        <% else %>
          <div class="flex items-center gap-2">
            <span class="w-3 h-3 rounded-full bg-yellow-500"></span>
            <span class="text-sm text-gray-600">Accumulated Energy</span>
            <span class="text-xs text-gray-400 ml-1">Goal: {@result.goal_energy}E</span>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # Event Handlers

  @impl true
  def handle_event("select_faction", %{"faction" => faction}, socket) do
    {:noreply, assign(socket, selected_faction: faction, active_filters: [])}
  end

  @impl true
  def handle_event("toggle_filter", %{"filter" => filter_key}, socket) do
    active_filters = socket.assigns.active_filters

    new_filters =
      if filter_key in active_filters do
        List.delete(active_filters, filter_key)
      else
        # Remove mutually exclusive filters from same group
        group_to_remove =
          cond do
            filter_key in @usage_filters -> @usage_filters
            filter_key in @tech_filters -> @tech_filters
            true -> []
          end

        active_filters
        |> Enum.reject(&(&1 in group_to_remove))
        |> Kernel.++([filter_key])
      end

    {:noreply, assign(socket, :active_filters, new_filters)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply, assign(socket, :active_filters, [])}
  end

  @impl true
  def handle_event("set_chart_view", %{"view" => view}, socket) do
    {:noreply, assign(socket, :chart_view, view)}
  end

  @impl true
  def handle_event("select_unit", %{"unit-id" => unit_id}, socket) do
    unit = Enum.find(socket.assigns.units, &(&1.unit_id == unit_id))

    {:noreply,
     socket
     |> assign(:selected_unit, unit)
     |> assign(:show_results, false)}
  end

  @impl true
  def handle_event("update_quantity", %{"value" => qty}, socket) do
    qty = String.to_integer(qty) |> max(1)

    {:noreply,
     socket
     |> assign(:goal_quantity, qty)
     |> assign(:show_results, false)}
  end

  @impl true
  def handle_event("update_" <> field, %{"value" => value}, socket) do
    field_atom = String.to_atom(field)

    {:noreply,
     socket
     |> assign(field_atom, value)
     |> assign(:show_results, false)}
  end

  @impl true
  def handle_event("run_simulation", _params, socket) do
    unit = socket.assigns.selected_unit
    quantity = socket.assigns.goal_quantity

    # Calculate total cost
    goal_mass = unit.build_cost_mass * quantity
    goal_energy = unit.build_cost_energy * quantity

    # Generate dummy result for UI prototype
    result = %{
      completion_time: 347,
      goal_quantity: quantity,
      goal_mass: goal_mass,
      goal_energy: goal_energy,
      unit_name: unit.name,
      milestones: [
        %{time: 0, label: "Start"},
        %{time: 120, label: "Mass storage full"},
        %{time: 234, label: "Energy threshold reached"},
        %{time: 347, label: "Goal Complete"}
      ]
    }

    {:noreply,
     socket
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

  defp format_unit_display_name(unit) do
    display_name = get_standardized_display_name(unit)
    tier_prefix = get_tier_prefix(unit)
    "#{tier_prefix}#{display_name}"
  end

  # List of unit descriptions that should be standardized across factions
  @standardized_descriptions [
    "Mass Extractor",
    "Mass Fabricator",
    "Energy Generator",
    "Hydrocarbon Power Plant"
  ]

  # Standardize display names for units that have faction-specific naming
  defp get_standardized_display_name(unit) do
    description = unit.description || "Unknown"

    # For units with standard descriptions, use description (ignoring faction-specific names)
    # This ensures "Mass Pump", "Hyalatoh" all show as "Mass Extractor"
    if description in @standardized_descriptions do
      description
    else
      # For other units, use nickname if available, otherwise description
      unit.name || description
    end
  end

  # Units that exist at multiple tech levels - these need tier prefix
  @multi_tier_units [
    "Mass Extractor",
    "Mass Fabricator",
    "Power Generator",
    "Energy Storage",
    "Mass Storage",
    "Engineer",
    "Land Factory",
    "Land Factory HQ",
    "Air Factory",
    "Air Factory HQ",
    "Naval Factory",
    "Naval Factory HQ",
    "Point Defense",
    "Anti-Air Turret",
    "Anti-Air Defense",
    "Anti-Air Flak Artillery",
    "Anti-Air SAM Launcher",
    "Artillery Installation",
    "Torpedo Launcher",
    "Radar System",
    "Sonar System"
  ]

  defp get_tier_prefix(unit) do
    description = unit.description || ""

    # Only add tier prefix for units that exist at multiple tech levels
    if description in @multi_tier_units do
      categories = unit.categories || []

      cond do
        "TECH1" in categories -> "T1 "
        "TECH2" in categories -> "T2 "
        "TECH3" in categories -> "T3 "
        "EXPERIMENTAL" in categories -> "EXP "
        true -> ""
      end
    else
      ""
    end
  end

  defp format_time(seconds) do
    mins = div(seconds, 60)
    secs = rem(seconds, 60)
    "#{mins}:#{String.pad_leading("#{secs}", 2, "0")}"
  end

  defp apply_filters(units, []), do: units

  defp apply_filters(units, active_filters) do
    Enum.filter(units, fn unit ->
      categories = unit.categories || []

      # Check if unit matches ALL active filters
      Enum.all?(active_filters, fn filter ->
        filter in categories
      end)
    end)
  end
end
