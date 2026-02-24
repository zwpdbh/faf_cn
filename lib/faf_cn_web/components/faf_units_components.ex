defmodule FafCnWeb.FafUnitsComponents do
  @moduledoc """
  Shared components for FAF unit selection and display.

  This module provides reusable components for:
  - Faction selection tabs
  - Filter bars (with optional eco filter)
  - Unit selection grids
  - Individual unit buttons/cards
  - Complete selection panels (inline) and modals

  ## Usage Examples

  ### Basic inline panel (for Eco Guides):

      <.unit_selection_panel
        units_by_faction={@units_by_faction}
        selected_faction={@selected_faction}
        selected_units={@selected_units}
        base_unit={@base_unit}
        active_filters={@active_filters}
      />

  ### Modal selector (for Eco Workflow):

      <.unit_selector_modal
        :if={@show_modal}
        units_by_faction={@units_by_faction}
        selected_faction={@selected_faction}
        current_unit_id={@current_unit_id}
        active_filters={@active_filters}
        show_eco_only={@show_eco_only}
      />
  """

  use FafCnWeb, :html

  import FafCnWeb.FafUnitsHelpers

  # ============================================================================
  # Faction Tabs
  # ============================================================================

  @doc """
  Renders faction selection tabs.

  ## Attributes

    * `factions` - List of faction names (default: all 4 factions)
    * `selected_faction` - Currently selected faction
    * `on_select` - Event name to trigger on selection (default: "select_faction")
  """
  attr :factions, :list, default: ["UEF", "CYBRAN", "AEON", "SERAPHIM"]
  attr :selected_faction, :string, required: true
  attr :on_select, :string, default: "select_faction"
  # :default | :pills
  attr :variant, :atom, default: :default

  def faction_tabs(assigns) do
    ~H"""
    <div class={tabs_container_class(@variant)}>
      <%= if @variant == :pills do %>
        <%!-- Pill-style tabs (for modals) --%>
        <div class="flex gap-2">
          <%= for faction <- @factions do %>
            <% is_active = @selected_faction == faction %>
            <button
              phx-click={@on_select}
              phx-value-faction={faction}
              class={[
                "flex-1 py-2 px-4 text-sm font-medium rounded-lg transition-all",
                faction_pill_class(faction, is_active)
              ]}
            >
              {faction}
            </button>
          <% end %>
        </div>
      <% else %>
        <%!-- Tab-style tabs (for inline panels) --%>
        <nav class="-mb-px flex space-x-8" aria-label="Tabs">
          <%= for faction <- @factions do %>
            <% is_active = @selected_faction == faction %>
            <button
              phx-click={@on_select}
              phx-value-faction={faction}
              class={[
                "whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm capitalize transition-colors",
                faction_tab_classes(faction, is_active)
              ]}
            >
              {faction}
            </button>
          <% end %>
        </nav>
      <% end %>
    </div>
    """
  end

  defp tabs_container_class(:pills), do: "flex gap-2 p-2 bg-base-200"
  defp tabs_container_class(_), do: "border-b border-gray-200"

  defp faction_pill_class(faction, is_active) do
    FafCnWeb.FafUnitsHelpers.faction_pill_classes(faction, is_active)
  end

  # ============================================================================
  # Filter Bar
  # ============================================================================

  @doc """
  Renders the filter bar with filter buttons.

  ## Attributes

    * `filters` - List of filter definitions [%{key, label, group}, ...]
    * `active_filters` - List of currently active filter keys
    * `variant` - Visual variant (:default | :with_eco | :grouped)
    * `eco_filter_active` - Whether eco-only filter is active (for :with_eco variant)
    * `label_class` - CSS classes for group labels (default: auto based on variant)
    * `on_toggle` - Event name for toggling filters (default: "toggle_filter")
    * `on_toggle_eco` - Event name for eco toggle (default: "toggle_eco_filter")
    * `on_clear` - Event name for clearing filters (default: "clear_filters")
  """
  attr :filters, :list, required: true
  attr :active_filters, :list, default: []
  # :default | :with_eco | :grouped
  attr :variant, :atom, default: :default
  attr :eco_filter_active, :boolean, default: false
  attr :label_class, :string, default: nil
  attr :on_toggle, :string, default: "toggle_filter"
  attr :on_toggle_eco, :string, default: "toggle_eco_filter"
  attr :on_clear, :string, default: "clear_filters"

  def filter_bar(assigns) do
    ~H"""
    <div class={filter_bar_container_class(@variant)}>
      <%= case @variant do %>
        <% :with_eco -> %>
          <%!-- Eco style: Eco toggle + grouped filters --%>
          <% label_class = @label_class || "text-xs font-semibold text-gray-600 mr-1" %>
          <.eco_filter_button active={@eco_filter_active} on_toggle={@on_toggle_eco} />
          <div class="w-px h-4 bg-base-300 mx-1"></div>
          <.filter_group
            filters={@filters}
            active_filters={@active_filters}
            group={:tech}
            label="Tech:"
            on_toggle={@on_toggle}
            label_class={label_class}
          />
          <div class="w-px h-4 bg-base-300 mx-1"></div>
          <.filter_group
            filters={@filters}
            active_filters={@active_filters}
            group={:type}
            label="Type:"
            on_toggle={@on_toggle}
            label_class={label_class}
          />
          <.clear_button
            :if={length(@active_filters) > 0 or @eco_filter_active}
            on_clear={@on_clear}
            variant={:with_eco}
          />
        <% :grouped -> %>
          <%!-- Grouped filters with labels --%>
          <.filter_group
            filters={@filters}
            active_filters={@active_filters}
            group={:tech}
            label="Tech:"
            on_toggle={@on_toggle}
            label_class="text-xs font-semibold text-base-content mr-1"
          />
          <div class="w-px h-4 bg-base-300 mx-1"></div>
          <.filter_group
            filters={@filters}
            active_filters={@active_filters}
            group={:usage}
            label="Type:"
            on_toggle={@on_toggle}
            label_class="text-xs font-semibold text-base-content mr-1"
          />
          <.clear_button
            :if={length(@active_filters) > 0}
            on_clear={@on_clear}
            variant={:default}
          />
        <% _ -> %>
          <%!-- Simple list of filters (original Eco Guides style) --%>
          <%= for filter <- @filters do %>
            <% is_active = filter.key in @active_filters %>
            <button
              phx-click={@on_toggle}
              phx-value-filter={filter.key}
              class={[
                FafCnWeb.FafUnitsHelpers.filter_button_base_classes(variant: :light),
                if is_active do
                  FafCnWeb.FafUnitsHelpers.filter_button_active_classes()
                else
                  FafCnWeb.FafUnitsHelpers.filter_button_inactive_classes(variant: :light)
                end
              ]}
            >
              {filter.label}
            </button>
          <% end %>
          <%= if length(@active_filters) > 0 do %>
            <.clear_button on_clear={@on_clear} variant={:default} />
          <% end %>
      <% end %>
    </div>
    """
  end

  defp filter_bar_container_class(:with_eco),
    do: "flex flex-wrap gap-x-2 gap-y-2 items-center"

  defp filter_bar_container_class(_),
    do: "flex flex-wrap gap-2 mb-2"

  defp eco_filter_button(assigns) do
    ~H"""
    <button
      phx-click={@on_toggle}
      class={FafCnWeb.FafUnitsHelpers.eco_filter_button_classes(@active, size: :xs, radius: :lg)}
    >
      <.icon name="hero-arrow-trending-up" class="w-3 h-3" /> Eco Only
    </button>
    """
  end

  attr :filters, :list, required: true
  attr :active_filters, :list, default: []
  attr :group, :atom, required: true
  attr :label, :string, required: true
  attr :on_toggle, :string, required: true
  attr :label_class, :string, default: "text-xs font-medium text-base-content/80 mr-1"

  defp filter_group(assigns) do
    ~H"""
    <span class={@label_class}>{@label}</span>
    <%= for filter <- Enum.filter(@filters, &(&1.group == @group)) do %>
      <% is_active = filter.key in @active_filters %>
      <button
        phx-click={@on_toggle}
        phx-value-filter={filter.key}
        class={[
          FafCnWeb.FafUnitsHelpers.filter_button_base_classes(size: :xs, radius: :lg),
          if is_active do
            FafCnWeb.FafUnitsHelpers.filter_button_active_classes()
          else
            FafCnWeb.FafUnitsHelpers.filter_button_inactive_classes()
          end
        ]}
      >
        {filter.label}
      </button>
    <% end %>
    """
  end

  defp clear_button(assigns) do
    ~H"""
    <button
      phx-click={@on_clear}
      class={clear_button_class(@variant)}
      title="Clear filters"
    >
      <.icon name="hero-trash" class="w-4 h-4" />
    </button>
    """
  end

  defp clear_button_class(:with_eco) do
    "ml-auto w-8 h-8 flex items-center justify-center rounded bg-gray-500/50 text-white hover:bg-gray-500/70 transition-all"
  end

  defp clear_button_class(_) do
    "w-8 h-8 flex items-center justify-center rounded bg-gray-500/50 text-white hover:bg-gray-500/70 transition-all"
  end

  # ============================================================================
  # Unit Grid
  # ============================================================================

  @doc """
  Renders a grid of selectable unit buttons.

  ## Attributes

    * `units` - List of units to display
    * `selected_unit_ids` - List of selected unit IDs (for multi-select)
    * `current_unit_id` - Currently selected unit ID (for single-select highlight)
    * `base_unit_id` - ID of the base unit (shown as locked/indicator)
    * `selection_mode` - :single or :multiple
    * `on_select` - Event name when a unit is clicked
    * `columns` - Grid column configuration (:default | :dense | :sparse)
    * `show_background` - Whether to show the background image
  """
  attr :units, :list, required: true
  attr :selected_unit_ids, :list, default: []
  attr :current_unit_id, :string, default: nil
  attr :base_unit_id, :string, default: nil
  # :single | :multiple
  attr :selection_mode, :atom, default: :multiple
  attr :on_select, :string, default: "select_unit"
  attr :columns, :atom, default: :default
  attr :show_background, :boolean, default: true
  attr :empty_state_text, :string, default: "No units match the selected filters."

  def unit_grid(assigns) do
    ~H"""
    <div class={grid_container_class(@show_background)}>
      <%= if @units == [] do %>
        <.empty_state text={@empty_state_text} on_clear="clear_filters" />
      <% else %>
        <div class={grid_columns_class(@columns)}>
          <%= for unit <- @units do %>
            <% is_selected =
              if @selection_mode == :single do
                unit.unit_id == @current_unit_id
              else
                unit.unit_id in @selected_unit_ids
              end

            is_base = unit.unit_id == @base_unit_id %>
            <.unit_button
              unit={unit}
              selected={is_selected}
              is_base={is_base}
              on_click={@on_select}
              variant={if @columns == :dense, do: :compact, else: :default}
            />
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp grid_container_class(true) do
    "flex-1 overflow-y-auto p-4 min-h-[400px]"
  end

  defp grid_container_class(false) do
    "p-4"
  end

  # Unified grid columns - consistent density across both features
  defp grid_columns_class(_) do
    "grid grid-cols-5 sm:grid-cols-6 md:grid-cols-8 lg:grid-cols-10 gap-3 content-start"
  end

  defp empty_state(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center h-full text-white/80">
      <.icon name="hero-squares-2x2" class="w-12 h-12 mb-2" />
      <p>{@text}</p>
      <button
        phx-click={@on_clear}
        class="mt-3 px-4 py-2 bg-white/20 hover:bg-white/30 rounded-lg text-sm transition-colors"
      >
        Clear filters
      </button>
    </div>
    """
  end

  # ============================================================================
  # Unit Button
  # ============================================================================

  @doc """
  Renders a single selectable unit button/card.

  ## Attributes

    * `unit` - The unit to display
    * `selected` - Whether this unit is selected
    * `is_base` - Whether this is the base unit (shows star, disabled)
    * `on_click` - Event name when clicked
    * `variant` - :default or :compact
  """
  attr :unit, :map, required: true
  attr :selected, :boolean, default: false
  attr :is_base, :boolean, default: false
  attr :on_click, :string, default: "select_unit"
  attr :variant, :atom, default: :default

  def unit_button(assigns) do
    ~H"""
    <button
      phx-click={if !@is_base, do: @on_click}
      phx-value-unit_id={@unit.unit_id}
      class={unit_button_classes(@unit, @selected, @is_base, @variant)}
      title={"#{format_unit_display_name(@unit)}: #{@unit.description || "No description"}"}
    >
      <div class={["unit-icon-#{@unit.unit_id}", icon_size_class(@variant)]}></div>

      <%= if @is_base do %>
        <span class={base_indicator_class(@variant)}>
          <span class="text-[8px] font-bold text-yellow-900">★</span>
        </span>
      <% end %>

      <%= if @selected && !@is_base do %>
        <span class={selection_indicator_class(@variant)}>
          <.icon name="hero-check" class={check_icon_size(@variant)} />
        </span>
      <% end %>
    </button>
    """
  end

  # Unified unit button styling - consistent across both Eco Guides and Eco Workflow
  defp unit_button_classes(unit, selected, is_base, _variant) do
    base_classes = [
      "group relative aspect-square rounded-xl p-1 transition-all duration-150 flex flex-col items-center justify-center text-center overflow-hidden shadow-sm",
      faction_bg_class(unit.faction)
    ]

    state_classes =
      cond do
        is_base ->
          "ring-2 ring-yellow-400 ring-offset-2 cursor-default"

        selected ->
          "ring-2 ring-yellow-400 ring-offset-2 shadow-lg scale-105"

        true ->
          "hover:ring-2 hover:ring-white/50 hover:ring-offset-2 hover:scale-105 hover:shadow-md cursor-pointer"
      end

    Enum.join(base_classes ++ [state_classes], " ")
  end

  # Unified icon size
  defp icon_size_class(_), do: "w-12 h-12 shrink-0"

  # Unified base unit indicator (star)
  defp base_indicator_class(_) do
    "absolute -top-1 -right-1 w-5 h-5 bg-yellow-400 rounded-full flex items-center justify-center z-10 shadow-md"
  end

  # Unified selection indicator (yellow checkmark)
  defp selection_indicator_class(_) do
    "absolute -top-1 -right-1 w-5 h-5 bg-yellow-400 rounded-full flex items-center justify-center z-10 shadow-md"
  end

  # Unified check icon
  defp check_icon_size(_), do: "w-3 h-3 text-yellow-900"

  # ============================================================================
  # Pre-composed Components
  # ============================================================================

  @doc """
  Complete inline unit selection panel (for Eco Guides style).

  ## Attributes

    * `units_by_faction` - Map of units grouped by faction
    * `selected_faction` - Currently selected faction
    * `selected_units` - List of selected units
    * `base_unit` - The base unit (shown as locked)
    * `active_filters` - Active filter keys
    * `show_eco_only` - Whether to show only eco units
  """
  attr :units_by_faction, :map, required: true
  attr :selected_faction, :string, required: true
  attr :selected_units, :list, default: []
  attr :base_unit, :any, default: nil
  attr :active_filters, :list, default: []
  attr :show_eco_only, :boolean, default: false
  attr :on_clear_selections, :string, default: "clear_selections"

  def unit_selection_panel(assigns) do
    faction_units = assigns.units_by_faction[assigns.selected_faction] || []

    filtered_units =
      apply_filters(faction_units, assigns.active_filters, eco_only: assigns.show_eco_only)

    assigns =
      assigns
      |> assign(:faction_units, faction_units)
      |> assign(:filtered_units, filtered_units)
      |> assign(:base_unit_id, assigns.base_unit && assigns.base_unit.unit_id)

    ~H"""
    <div
      class="rounded-lg shadow-sm border border-gray-200 p-4"
      style="background-image: url('/images/units/background.jpg'); background-size: cover; background-position: center;"
    >
      <%!-- Header with selection count --%>
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-lg font-semibold text-white drop-shadow-md">
          Select Units to Compare
        </h2>
        <%= if length(@selected_units) > 0 do %>
          <button
            phx-click={@on_clear_selections}
            class="text-sm bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded transition-colors shadow-md"
          >
            Clear ({length(@selected_units)})
          </button>
        <% end %>
      </div>

      <%!-- Filter Bar with Eco Only (dark background) --%>
      <.filter_bar
        filters={all_filters()}
        active_filters={@active_filters}
        variant={:with_eco}
        eco_filter_active={@show_eco_only}
        label_class="text-xs font-medium text-white/90 mr-1"
      />

      <%!-- Unit Grid --%>
      <.unit_grid
        units={@filtered_units}
        selected_unit_ids={Enum.map(@selected_units, & &1.unit_id)}
        base_unit_id={@base_unit_id}
        selection_mode={:multiple}
        on_select="toggle_unit"
        show_background={false}
      />
    </div>
    """
  end

  @doc """
  Complete modal unit selector (for Eco Workflow style).

  ## Attributes

    * `show` - Whether to show the modal
    * `units_by_faction` - Map of units grouped by faction
    * `selected_faction` - Currently selected faction
    * `current_unit_id` - Currently selected unit ID (for highlighting)
    * `active_filters` - Active filter keys
    * `show_eco_only` - Whether eco-only filter is active
  """
  attr :show, :boolean, default: false
  attr :units_by_faction, :map, required: true
  attr :selected_faction, :string, required: true
  attr :current_unit_id, :string, default: nil
  attr :active_filters, :list, default: []
  attr :show_eco_only, :boolean, default: false
  attr :on_close, :string, default: "close_unit_selector"
  attr :on_select_unit, :string, default: "select_unit_for_node"

  def unit_selector_modal(assigns) do
    faction_units = assigns.units_by_faction[assigns.selected_faction] || []

    filtered_units =
      apply_filters(faction_units, assigns.active_filters, eco_only: assigns.show_eco_only)

    assigns =
      assigns
      |> assign(:faction_units, faction_units)
      |> assign(:filtered_units, filtered_units)
      |> assign(:eco_filter_active, assigns.show_eco_only)

    ~H"""
    <div
      :if={@show}
      class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
      phx-click={@on_close}
    >
      <div
        class="bg-base-100 rounded-2xl shadow-2xl w-full max-w-4xl h-[80vh] flex flex-col overflow-hidden"
        phx-click-away={@on_close}
        phx-stop
      >
        <%!-- Modal Header --%>
        <div class="p-4 border-b border-base-300 flex items-center justify-between bg-base-200 rounded-t-2xl">
          <h2 class="text-lg font-semibold">Select Unit</h2>
          <button
            class="btn btn-sm btn-ghost rounded-lg"
            phx-click={@on_close}
          >
            <.icon name="hero-x-mark" class="w-5 h-5" />
          </button>
        </div>

        <%!-- Faction Tabs --%>
        <.faction_tabs
          selected_faction={@selected_faction}
          variant={:pills}
        />

        <%!-- Filter Bar --%>
        <div class="p-3 border-b border-base-300 bg-base-100">
          <.filter_bar
            filters={all_filters()}
            active_filters={@active_filters}
            variant={:with_eco}
            eco_filter_active={@eco_filter_active}
          />
        </div>

        <%!-- Unit Grid --%>
        <div
          class="flex-1 overflow-y-auto p-4 min-h-[400px]"
          style="background-image: url('/images/units/background.jpg'); background-size: cover; background-position: center;"
        >
          <.unit_grid
            units={@filtered_units}
            current_unit_id={@current_unit_id}
            selection_mode={:single}
            on_select={@on_select_unit}
            show_background={false}
          />
        </div>

        <%!-- Modal Footer --%>
        <div class="p-3 border-t border-base-300 text-sm text-base-content/60 text-center bg-base-200 rounded-b-2xl">
          Click a unit to select it • Yellow checkmark = current selection
        </div>
      </div>
    </div>
    """
  end
end
