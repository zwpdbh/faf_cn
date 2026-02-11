defmodule FafCnWeb.EcoGuidesLive.Components do
  @moduledoc """
  Components for the Eco Guides LiveView.

  This module contains reusable components for:
  - Unit selection interface
  - Eco comparison display
  """

  use FafCnWeb, :html

  @doc """
  Renders faction selection tabs.

  ## Attributes

    * `factions` - List of faction names
    * `selected_faction` - Currently selected faction
  """
  attr :factions, :list, required: true
  attr :selected_faction, :string, required: true

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

              _ ->
                if is_active,
                  do: "border-indigo-500 text-indigo-600",
                  else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
            end %>
          <button
            phx-click="select_faction"
            phx-value-faction={faction}
            class={[
              "whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm capitalize transition-colors",
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

  @doc """
  Renders the base unit (Engineer) display card.

  ## Attributes

    * `base_unit` - The base engineer unit struct
    * `selected_faction` - Currently selected faction for styling
  """
  attr :base_unit, :any, required: true
  attr :selected_faction, :string, required: true

  def base_unit_card(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
      <div class="flex items-center justify-between mb-3">
        <h2 class="text-lg font-semibold text-gray-900">Base Unit (Engineer)</h2>
        <span class={[
          "px-2 py-1 text-xs font-medium rounded-full",
          faction_badge_class(@selected_faction)
        ]}>
          {@selected_faction}
        </span>
      </div>
      <%= if @base_unit do %>
        <div class="flex items-center space-x-4">
          <%!-- Engineer Icon --%>
          <div class={[
            "w-16 h-16 rounded-lg flex items-center justify-center shadow-inner",
            unit_faction_bg_class(@base_unit.faction)
          ]}>
            <div class={"unit-icon-#{@base_unit.unit_id} w-14 h-14"}></div>
          </div>
          <div class="flex-1">
            <div class="flex items-center space-x-2">
              <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-800">
                {unit_tech_badge(@base_unit)}
              </span>
              <h3 class="font-semibold text-gray-900">{@base_unit.unit_id}</h3>
            </div>
            <p class="text-sm text-gray-600">
              {@base_unit.description || @base_unit.name || "Engineer"}
            </p>
            <div class="mt-1 flex items-center space-x-4 text-xs text-gray-500">
              <span>Mass: {format_number(@base_unit.build_cost_mass)}</span>
              <span>Energy: {format_number(@base_unit.build_cost_energy)}</span>
              <span>BT: {format_number(@base_unit.build_time)}</span>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders the unit selection grid with filters.

  ## Attributes

    * `units_by_faction` - Map of units grouped by faction
    * `selected_faction` - Currently selected faction
    * `selected_units` - List of currently selected units
    * `base_unit` - The base engineer unit
    * `filters` - List of available filter definitions
    * `active_filters` - List of currently active filter keys
  """
  attr :units_by_faction, :map, required: true
  attr :selected_faction, :string, required: true
  attr :selected_units, :list, required: true
  attr :base_unit, :any, required: true
  attr :filters, :list, required: true
  attr :active_filters, :list, required: true

  def unit_selection_grid(assigns) do
    ~H"""
    <% faction_units = @units_by_faction[@selected_faction] || []
    filtered_units = apply_filters(faction_units, @active_filters) %>
    <div
      class="rounded-lg shadow-sm border border-gray-200 p-4"
      style="background-image: url('/images/units/background.jpg'); background-size: cover; background-position: center;"
    >
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-lg font-semibold text-white drop-shadow-md">
          Select Units to Compare
        </h2>
        <%= if length(@selected_units) > 0 do %>
          <button
            phx-click="clear_selections"
            class="text-sm bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded transition-colors shadow-md"
          >
            Clear ({length(@selected_units)})
          </button>
        <% end %>
      </div>

      <%!-- Filter Bar --%>
      <.filter_bar filters={@filters} active_filters={@active_filters} />

      <%!-- Unit Grid --%>
      <div class="grid grid-cols-4 sm:grid-cols-6 md:grid-cols-8 gap-3 mt-4">
        <%= for unit <- filtered_units do %>
          <% is_selected = unit_selected?(@selected_units, unit.unit_id)
          is_engineer = unit.unit_id == @base_unit.unit_id

          border_class =
            cond do
              is_engineer -> "ring-2 ring-yellow-400 ring-offset-1 cursor-default"
              is_selected -> "ring-2 ring-indigo-500 ring-offset-1"
              true -> "hover:ring-2 hover:ring-gray-300 hover:ring-offset-1 cursor-pointer"
            end %>
          <button
            phx-click={if !is_engineer, do: "toggle_unit"}
            phx-value-unit_id={unit.unit_id}
            class={[
              "group relative aspect-square rounded-lg p-1 transition-all duration-150 flex flex-col items-center justify-center text-center overflow-hidden",
              unit_faction_bg_class(unit.faction),
              border_class
            ]}
            title={"#{unit.unit_id} - #{unit.description || unit.name || "Unknown"}"}
          >
            <%!-- Unit icon from sprite sheet --%>
            <div class={["unit-icon-#{unit.unit_id} w-12 h-12 flex-shrink-0"]}></div>
            <%= if is_engineer do %>
              <span class="absolute -top-1 -right-1 w-4 h-4 bg-yellow-400 rounded-full flex items-center justify-center z-10">
                <span class="text-[8px] font-bold text-yellow-900">★</span>
              </span>
            <% end %>
            <%= if is_selected do %>
              <span class="absolute -top-1 -right-1 w-4 h-4 bg-indigo-500 rounded-full flex items-center justify-center z-10">
                <.icon name="hero-check" class="w-3 h-3 text-white" />
              </span>
            <% end %>
          </button>
        <% end %>
      </div>

      <%= if filtered_units == [] do %>
        <div class="text-center py-8 text-white/70">
          <p>No units match the selected filters.</p>
          <button
            phx-click="clear_filters"
            class="mt-2 text-sm underline hover:text-white"
          >
            Clear filters
          </button>
        </div>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders the filter bar with filter buttons.
  """
  attr :filters, :list, required: true
  attr :active_filters, :list, required: true

  def filter_bar(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-2 mb-2">
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

  @doc """
  Renders the eco comparison panel showing comparisons between selected units and the base engineer.

  ## Attributes

    * `base_unit` - The base engineer unit
    * `selected_units` - List of selected units to compare
    * `current_user` - Current logged-in user (nil if not logged in)
  """
  attr :base_unit, :any, required: true
  attr :selected_units, :list, required: true
  attr :current_user, :any, default: nil

  def eco_comparison(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
      <h2 class="text-lg font-semibold text-gray-900 mb-4">Eco Comparison</h2>

      <%= if length(@selected_units) == 0 do %>
        <.empty_comparison_state />
      <% else %>
        <div class="space-y-4">
          <.base_unit_comparison
            base_unit={@base_unit}
            selected_units={@selected_units}
            current_user={@current_user}
          />
          <.cross_unit_comparison
            base_unit={@base_unit}
            selected_units={@selected_units}
            current_user={@current_user}
          />
          <.comparison_summary_stats selected_units={@selected_units} />
        </div>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders the empty state when no units are selected.
  """
  def empty_comparison_state(assigns) do
    ~H"""
    <div class="text-center py-8 text-gray-500">
      <.icon name="hero-calculator" class="mx-auto h-10 w-10 text-gray-300 mb-3" />
      <p class="text-sm">Select units to see comparisons against the Engineer.</p>
    </div>
    """
  end

  @doc """
  Renders the base unit comparison section.

  ## Attributes

    * `base_unit` - The base engineer unit
    * `selected_units` - List of selected units
    * `current_user` - Current logged-in user (nil if not logged in)
  """
  attr :base_unit, :any, required: true
  attr :selected_units, :list, required: true
  attr :current_user, :any, default: nil

  def base_unit_comparison(assigns) do
    ~H"""
    <div>
      <div class="bg-gray-100 rounded-lg p-2 mb-3 border border-gray-200">
        <div class="flex items-center gap-2 mb-2">
          <div class={[
            "w-8 h-8 rounded flex-shrink-0 overflow-hidden relative",
            unit_faction_bg_class(@base_unit.faction)
          ]}>
            <div
              class={"unit-icon-#{@base_unit.unit_id} absolute"}
              style="width: 64px; height: 64px; transform: scale(0.5); transform-origin: top left;"
            >
            </div>
          </div>
          <div class="flex-1 min-w-0">
            <a
              href={~p"/units/#{@base_unit.unit_id}"}
              class="text-xs font-semibold text-gray-900 truncate hover:text-indigo-600"
            >
              {@base_unit.description || @base_unit.name || "Engineer"}
            </a>
            <p class="text-[10px] text-gray-500">{@base_unit.unit_id}</p>
          </div>
        </div>
        <%!-- Base Unit Absolute Eco Values --%>
        <div class="grid grid-cols-3 gap-1 text-[10px] text-center">
          <div class="bg-white rounded p-1">
            <span class="block text-gray-400">Mass</span>
            <span class="font-semibold text-gray-700">
              {format_number(@base_unit.build_cost_mass)}
            </span>
          </div>
          <div class="bg-white rounded p-1">
            <span class="block text-gray-400">Energy</span>
            <span class="font-semibold text-gray-700">
              {format_number(@base_unit.build_cost_energy)}
            </span>
          </div>
          <div class="bg-white rounded p-1">
            <span class="block text-gray-400">BT</span>
            <span class="font-semibold text-gray-700">
              {format_number(@base_unit.build_time)}
            </span>
          </div>
        </div>
      </div>
      <div class="space-y-2">
        <%= for {unit, _idx, ratio} <- generate_engineer_comparisons(@base_unit, @selected_units) do %>
          <div class="bg-gray-50 rounded-lg p-2 border border-gray-200">
            <div class="flex items-center gap-2 mb-2">
              <%!-- Unit Icon --%>
              <div class={[
                "w-8 h-8 rounded flex-shrink-0 overflow-hidden relative",
                unit_faction_bg_class(unit.faction)
              ]}>
                <div
                  class={"unit-icon-#{unit.unit_id} absolute"}
                  style="width: 64px; height: 64px; transform: scale(0.5); transform-origin: top left;"
                >
                </div>
              </div>
              <div class="flex-1 min-w-0">
                <a
                  href={~p"/units/#{unit.unit_id}"}
                  class="text-xs font-medium text-gray-900 truncate hover:text-indigo-600"
                >
                  {unit.description || unit.name || unit.unit_id}
                </a>
              </div>
              <span class={[
                "px-1.5 py-0.5 rounded text-[10px] font-medium flex-shrink-0",
                ratio_badge_class(ratio.mass)
              ]}>
                {ratio.mass}x
              </span>
            </div>
            <div class="grid grid-cols-3 gap-2 text-xs">
              <div class="text-center">
                <span class="block text-gray-400">Mass</span>
                <span class={ratio_color_class(ratio.mass)}>{ratio.mass}x</span>
              </div>
              <div class="text-center">
                <span class="block text-gray-400">Energy</span>
                <span class={ratio_color_class(ratio.energy)}>{ratio.energy}x</span>
              </div>
              <div class="text-center">
                <span class="block text-gray-400">Time</span>
                <span class={ratio_color_class(ratio.build_time)}>
                  {ratio.build_time}x
                </span>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Renders the cross-unit comparison section for tiered comparisons.

  ## Attributes

    * `base_unit` - The base engineer unit
    * `selected_units` - List of selected units
    * `current_user` - Current logged-in user (nil if not logged in)
  """
  attr :base_unit, :any, required: true
  attr :selected_units, :list, required: true
  attr :current_user, :any, default: nil

  def cross_unit_comparison(assigns) do
    ~H"""
    <%= if length(@selected_units) >= 2 do %>
      <div class="border-t pt-4">
        <h3 class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">
          Cross Comparisons
        </h3>
        <div class="space-y-3">
          <%= for {base_unit, comparisons} <- generate_tiered_cross_comparisons(@base_unit, @selected_units) do %>
            <%!-- Card for each base unit --%>
            <div class="bg-gray-50 rounded-lg p-2 border border-gray-200">
              <%!-- Base unit header --%>
              <div class="flex items-center gap-2 mb-2 pb-2 border-b border-gray-200">
                <div class={[
                  "w-6 h-6 rounded flex-shrink-0 overflow-hidden relative",
                  unit_faction_bg_class(base_unit.faction)
                ]}>
                  <div
                    class={"unit-icon-#{base_unit.unit_id} absolute"}
                    style="width: 64px; height: 64px; transform: scale(0.375); transform-origin: top left;"
                  >
                  </div>
                </div>
                <div class="flex-1 min-w-0">
                  <a
                    href={~p"/units/#{base_unit.unit_id}"}
                    class="text-xs font-medium text-gray-700 truncate block hover:text-indigo-600"
                  >
                    {base_unit.description || base_unit.name || base_unit.unit_id}
                  </a>
                  <span class="text-[10px] text-gray-500">
                    Mass: {format_number(base_unit.build_cost_mass)}
                  </span>
                </div>
              </div>
              <%!-- Comparisons against this base --%>
              <div class="space-y-1.5">
                <%= for {target_unit, ratio} <- comparisons do %>
                  <div class="flex items-center justify-between py-1">
                    <div class="flex items-center gap-2">
                      <%!-- To Unit --%>
                      <div class={[
                        "w-8 h-8 rounded flex-shrink-0 overflow-hidden relative",
                        unit_faction_bg_class(target_unit.faction)
                      ]}>
                        <div
                          class={"unit-icon-#{target_unit.unit_id} absolute"}
                          style="width: 64px; height: 64px; transform: scale(0.5); transform-origin: top left;"
                        >
                        </div>
                      </div>
                      <a
                        href={~p"/units/#{target_unit.unit_id}"}
                        class="text-xs text-gray-700 truncate hover:text-indigo-600"
                      >
                        {target_unit.description || target_unit.name ||
                          target_unit.unit_id}
                      </a>
                    </div>
                    <span class={[
                      "px-1.5 py-0.5 rounded text-[10px] font-medium flex-shrink-0",
                      ratio_badge_class(ratio.mass)
                    ]}>
                      {ratio.mass}x
                    </span>
                  </div>
                  <div class="grid grid-cols-3 gap-1 text-[10px] text-center">
                    <div>
                      <span class="block text-gray-400">Mass</span>
                      <span class={ratio_color_class(ratio.mass)}>{ratio.mass}x</span>
                    </div>
                    <div>
                      <span class="block text-gray-400">Energy</span>
                      <span class={ratio_color_class(ratio.energy)}>
                        {ratio.energy}x
                      </span>
                    </div>
                    <div>
                      <span class="block text-gray-400">Time</span>
                      <span class={ratio_color_class(ratio.build_time)}>
                        {ratio.build_time}x
                      </span>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  @doc """
  Renders the comparison summary statistics.

  ## Attributes

    * `selected_units` - List of selected units
  """
  attr :selected_units, :list, required: true

  def comparison_summary_stats(assigns) do
    ~H"""
    <div class="border-t pt-4 mt-4">
      <h3 class="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">
        Quick Stats
      </h3>
      <div class="grid grid-cols-2 gap-2 text-xs">
        <div class="bg-gray-50 rounded p-2">
          <span class="block text-gray-500">Total Mass</span>
          <span class="font-semibold text-gray-900">
            {format_number(Enum.sum(Enum.map(@selected_units, & &1.build_cost_mass)))}
          </span>
        </div>
        <div class="bg-gray-50 rounded p-2">
          <span class="block text-gray-500">Total Energy</span>
          <span class="font-semibold text-gray-900">
            {format_number(Enum.sum(Enum.map(@selected_units, & &1.build_cost_energy)))}
          </span>
        </div>
      </div>
    </div>
    """
  end

  # Helper functions (moved from EcoGuidesLive)

  @doc """
  Checks if a unit is currently selected.
  """
  def unit_selected?(selected_units, unit_id) do
    Enum.any?(selected_units, &(&1.unit_id == unit_id))
  end

  @doc """
  Applies active filters to a list of units.
  """
  def apply_filters(units, []), do: units

  def apply_filters(units, active_filters) do
    Enum.filter(units, fn unit ->
      categories = unit.categories || []

      Enum.all?(active_filters, fn filter_key ->
        filter_key in categories
      end)
    end)
  end

  @doc """
  Gets the faction background class for unit icons.
  """
  def unit_faction_bg_class(faction) do
    case faction do
      "UEF" -> "unit-bg-uef"
      "CYBRAN" -> "unit-bg-cybran"
      "AEON" -> "unit-bg-aeon"
      "SERAPHIM" -> "unit-bg-seraphim"
      _ -> "unit-bg-uef"
    end
  end

  @doc """
  Gets badge color class for a faction.
  """
  def faction_badge_class(faction) do
    case faction do
      "UEF" -> "bg-blue-100 text-blue-800"
      "CYBRAN" -> "bg-red-100 text-red-800"
      "AEON" -> "bg-emerald-100 text-emerald-800"
      "SERAPHIM" -> "bg-violet-100 text-violet-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  @doc """
  Gets the tech level display for a unit.
  """
  def unit_tech_badge(unit) do
    case get_tech_level(unit) do
      1 -> "T1"
      2 -> "T2"
      3 -> "T3"
      4 -> "EXP"
      _ -> "T1"
    end
  end

  @doc """
  Formats a number with commas for thousands.
  """
  def format_number(nil), do: "0"
  def format_number(n) when n < 1000, do: to_string(n)

  def format_number(n) do
    n
    |> to_string()
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end

  @doc """
  Returns color class based on ratio value.
  """
  def ratio_color_class(ratio) when ratio < 0.8, do: "text-green-600 font-semibold"
  def ratio_color_class(ratio) when ratio > 5, do: "text-red-600 font-semibold"
  def ratio_color_class(ratio) when ratio > 1.5, do: "text-orange-500 font-semibold"
  def ratio_color_class(_ratio), do: "text-yellow-600 font-medium"

  @doc """
  Returns badge color class based on ratio value.
  """
  def ratio_badge_class(ratio) when ratio < 0.8, do: "bg-green-100 text-green-800"
  def ratio_badge_class(ratio) when ratio > 5, do: "bg-red-100 text-red-800"
  def ratio_badge_class(ratio) when ratio > 1.5, do: "bg-orange-100 text-orange-800"
  def ratio_badge_class(_ratio), do: "bg-yellow-100 text-yellow-800"

  @doc """
  Generates comparisons specifically against the base unit (engineer).
  """
  def generate_engineer_comparisons(base_unit, selected_units) do
    selected_units
    |> Enum.with_index()
    |> Enum.map(fn {unit, idx} ->
      ratio = calculate_eco_ratio(base_unit, unit)
      {unit, idx, ratio}
    end)
  end

  @doc """
  Generates tiered cross-comparison groups for the selected units.
  """
  def generate_tiered_cross_comparisons(base_unit, selected_units) do
    # Combine all units and sort by mass (cheapest first)
    all_units = [base_unit | selected_units]
    sorted_units = Enum.sort_by(all_units, & &1.build_cost_mass)

    # Generate tiered groups
    sorted_units
    |> Enum.with_index()
    |> Enum.flat_map(fn {base, idx} ->
      remaining = Enum.drop(sorted_units, idx + 1)

      if remaining == [] do
        # Skip the last unit - nothing to compare against
        []
      else
        # Generate comparisons from base to each remaining unit
        comparisons =
          remaining
          |> Enum.map(fn target ->
            ratio = calculate_eco_ratio(base, target)
            {target, ratio}
          end)

        [{base, comparisons}]
      end
    end)
  end

  defp get_tech_level(unit) do
    categories = unit.categories || []

    cond do
      "TECH1" in categories -> 1
      "TECH2" in categories -> 2
      "TECH3" in categories -> 3
      "EXPERIMENTAL" in categories -> 4
      true -> 1
    end
  end

  defp calculate_eco_ratio(base_unit, compare_unit)
       when is_nil(base_unit) or is_nil(compare_unit) do
    nil
  end

  defp calculate_eco_ratio(base_unit, compare_unit) do
    base_mass = max(base_unit.build_cost_mass, 1)
    base_energy = max(base_unit.build_cost_energy, 1)
    base_time = max(base_unit.build_time, 1)

    compare_mass = max(compare_unit.build_cost_mass, 1)
    compare_energy = max(compare_unit.build_cost_energy, 1)
    compare_time = max(compare_unit.build_time, 1)

    mass_ratio = Float.round(compare_mass / base_mass, 2)
    energy_ratio = Float.round(compare_energy / base_energy, 2)
    time_ratio = Float.round(compare_time / base_time, 2)

    %{mass: mass_ratio, energy: energy_ratio, build_time: time_ratio}
  end
end
