defmodule FafCnWeb.EcoGuidesLive.Components do
  @moduledoc """
  Components for the Eco Guides LiveView.

  This module contains reusable components for:
  - Unit selection interface
  - Eco comparison display

  Note: This module now uses shared helpers from FafUnitsHelpers.
  Consider using FafUnitsComponents for new features.
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
          <% is_active = @selected_faction == faction %>
          <button
            phx-click="select_faction"
            phx-value-faction={faction}
            class={FafCnWeb.FafUnitsHelpers.faction_tab_classes(faction, is_active)}
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
          FafCnWeb.FafUnitsHelpers.faction_badge_class(@selected_faction)
        ]}>
          {@selected_faction}
        </span>
      </div>
      <%= if @base_unit do %>
        <div class="flex items-center space-x-4">
          <%!-- Engineer Icon --%>
          <div class={[
            "w-16 h-16 rounded-lg flex items-center justify-center shadow-inner",
            FafCnWeb.FafUnitsHelpers.faction_bg_class(@base_unit.faction)
          ]}>
            <div class={"unit-icon-#{@base_unit.unit_id} w-14 h-14"}></div>
          </div>
          <div class="flex-1">
            <div class="flex items-center space-x-2">
              <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-800">
                {FafCnWeb.FafUnitsHelpers.tech_badge(@base_unit)}
              </span>
              <h3 class="font-semibold text-gray-900">{@base_unit.unit_id}</h3>
            </div>
            <p class="text-sm text-gray-600">
              {FafCnWeb.FafUnitsHelpers.format_unit_display_name(@base_unit)}
            </p>
            <div class="mt-1 flex items-center space-x-4 text-xs text-gray-500">
              <span>Mass: {FafCnWeb.FafUnitsHelpers.format_number(@base_unit.build_cost_mass)}</span>
              <span>
                Energy: {FafCnWeb.FafUnitsHelpers.format_number(@base_unit.build_cost_energy)}
              </span>
              <span>BT: {FafCnWeb.FafUnitsHelpers.format_number(@base_unit.build_time)}</span>
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
    * `active_filters` - List of currently active filter keys
    * `show_eco_only` - Whether to show only eco units
  """
  attr :units_by_faction, :map, required: true
  attr :selected_faction, :string, required: true
  attr :selected_units, :list, required: true
  attr :base_unit, :any, required: true
  attr :filters, :list, required: true
  attr :active_filters, :list, required: true
  attr :show_eco_only, :boolean, default: false

  def unit_selection_grid(assigns) do
    ~H"""
    <FafCnWeb.FafUnitsComponents.unit_selection_panel
      units_by_faction={@units_by_faction}
      selected_faction={@selected_faction}
      selected_units={@selected_units}
      base_unit={@base_unit}
      active_filters={@active_filters}
      show_eco_only={@show_eco_only}
    />
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
            "w-8 h-8 rounded shrink-0 overflow-hidden relative",
            FafCnWeb.FafUnitsHelpers.faction_bg_class(@base_unit.faction)
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
              {FafCnWeb.FafUnitsHelpers.format_number(@base_unit.build_cost_mass)}
            </span>
          </div>
          <div class="bg-white rounded p-1">
            <span class="block text-gray-400">Energy</span>
            <span class="font-semibold text-gray-700">
              {FafCnWeb.FafUnitsHelpers.format_number(@base_unit.build_cost_energy)}
            </span>
          </div>
          <div class="bg-white rounded p-1">
            <span class="block text-gray-400">BT</span>
            <span class="font-semibold text-gray-700">
              {FafCnWeb.FafUnitsHelpers.format_number(@base_unit.build_time)}
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
                "w-8 h-8 rounded shrink-0 overflow-hidden relative",
                FafCnWeb.FafUnitsHelpers.faction_bg_class(unit.faction)
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
                  {FafCnWeb.FafUnitsHelpers.format_unit_display_name(unit)}
                </a>
              </div>
              <span class={[
                "px-1.5 py-0.5 rounded text-[10px] font-medium shrink-0",
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
                  "w-6 h-6 rounded shrink-0 overflow-hidden relative",
                  FafCnWeb.FafUnitsHelpers.faction_bg_class(base_unit.faction)
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
                    {FafCnWeb.FafUnitsHelpers.format_unit_display_name(base_unit)}
                  </a>
                  <span class="text-[10px] text-gray-500">
                    Mass: {FafCnWeb.FafUnitsHelpers.format_number(base_unit.build_cost_mass)}
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
                        "w-8 h-8 rounded shrink-0 overflow-hidden relative",
                        FafCnWeb.FafUnitsHelpers.faction_bg_class(target_unit.faction)
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
                        {FafCnWeb.FafUnitsHelpers.format_unit_display_name(target_unit)}
                      </a>
                    </div>
                    <span class={[
                      "px-1.5 py-0.5 rounded text-[10px] font-medium shrink-0",
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
            {FafCnWeb.FafUnitsHelpers.format_number(
              Enum.sum(Enum.map(@selected_units, & &1.build_cost_mass))
            )}
          </span>
        </div>
        <div class="bg-gray-50 rounded p-2">
          <span class="block text-gray-500">Total Energy</span>
          <span class="font-semibold text-gray-900">
            {FafCnWeb.FafUnitsHelpers.format_number(
              Enum.sum(Enum.map(@selected_units, & &1.build_cost_energy))
            )}
          </span>
        </div>
      </div>
    </div>
    """
  end

  # Helper functions (some imported from FafUnitsHelpers)

  # The following functions are imported from FafUnitsHelpers:
  # - unit_selected?/2
  # - apply_filters/2
  # - unit_faction_bg_class/1
  # - faction_badge_class/1
  # - unit_tech_badge/1
  # - format_unit_display_name/1
  # - format_number/1
  # - get_tech_level/1

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

    # Generate tiered groups - skip last unit (nothing to compare against)
    sorted_units
    |> Enum.with_index()
    |> Enum.reject(fn {_base, idx} -> idx == length(sorted_units) - 1 end)
    |> Enum.flat_map(fn {base, idx} ->
      remaining = Enum.drop(sorted_units, idx + 1)
      comparisons = build_comparisons(base, remaining)
      [{base, comparisons}]
    end)
  end

  defp build_comparisons(base_unit, targets) do
    Enum.map(targets, fn target ->
      ratio = calculate_eco_ratio(base_unit, target)
      {target, ratio}
    end)
  end

  # get_tech_level/1 is imported from FafUnitsHelpers

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
