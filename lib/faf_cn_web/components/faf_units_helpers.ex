defmodule FafCnWeb.FafUnitsHelpers do
  @moduledoc """
  Shared helper functions for FAF unit selection and display components.

  This module provides:
  - Standard filter definitions (tech, type, usage)
  - Filtering logic for unit lists
  - Styling helpers for factions and tech levels
  - Unit display formatting
  """

  # ============================================================================
  # Filter Definitions
  # ============================================================================

  @doc """
  Returns the standard tech level filters.
  """
  def tech_filters do
    [
      %{key: "TECH1", label: "T1", category: "TECH1", group: :tech},
      %{key: "TECH2", label: "T2", category: "TECH2", group: :tech},
      %{key: "TECH3", label: "T3", category: "TECH3", group: :tech},
      %{key: "EXPERIMENTAL", label: "EXP", category: "EXPERIMENTAL", group: :tech}
    ]
  end

  @doc """
  Returns the standard unit type filters.
  """
  def type_filters do
    [
      %{key: "ENGINEER", label: "Engineer", category: "ENGINEER", group: :type},
      %{key: "STRUCTURE", label: "Structure", category: "STRUCTURE", group: :type},
      %{key: "LAND", label: "Land", category: "LAND", group: :type},
      %{key: "AIR", label: "Air", category: "AIR", group: :type},
      %{key: "NAVAL", label: "Naval", category: "NAVAL", group: :type}
    ]
  end

  @doc """
  Returns all standard filters combined.
  """
  def all_filters do
    tech_filters() ++ type_filters()
  end

  @doc """
  Returns the eco-expanding unit categories (mass, energy, or build power producers).
  """
  def eco_categories do
    [
      "MASSEXTRACTION",
      "MASSFABRICATION",
      "MASSSTORAGE",
      "ENERGYPRODUCTION",
      "ENERGYSTORAGE",
      "HYDROCARBON",
      "ENGINEER"
    ]
  end

  @doc """
  Returns filter keys for mutually exclusive usage filters.
  """
  def usage_filter_keys do
    ["ENGINEER", "STRUCTURE", "LAND", "AIR", "NAVAL"]
  end

  @doc """
  Returns filter keys for mutually exclusive tech filters.
  """
  def tech_filter_keys do
    ["TECH1", "TECH2", "TECH3", "EXPERIMENTAL"]
  end

  # ============================================================================
  # Filtering Logic
  # ============================================================================

  @doc """
  Applies active filters to a list of units.

  ## Options

    * `:eco_only` - When true, only include eco-expanding units (default: false)
    * `:eco_categories` - Custom list of eco categories (default: from `eco_categories/0`)

  ## Examples

      iex> apply_filters(units, ["TECH1", "ENGINEER"])
      [%Unit{categories: ["TECH1", "ENGINEER", ...]}, ...]

      iex> apply_filters(units, [], eco_only: true)
      [%Unit{categories: ["MASSEXTRACTION", ...]}, ...]
  """
  def apply_filters(units, active_filters, opts \\ []) do
    eco_only = Keyword.get(opts, :eco_only, false)
    eco_cats = Keyword.get(opts, :eco_categories, eco_categories())

    units
    |> maybe_filter_by_eco(eco_only, eco_cats)
    |> filter_by_categories(active_filters)
  end

  defp maybe_filter_by_eco(units, false, _eco_cats), do: units

  defp maybe_filter_by_eco(units, true, eco_cats) do
    Enum.filter(units, fn unit ->
      categories = unit.categories || []
      Enum.any?(eco_cats, &(&1 in categories))
    end)
  end

  defp filter_by_categories(units, []), do: units

  defp filter_by_categories(units, active_filters) do
    Enum.filter(units, fn unit ->
      categories = unit.categories || []
      Enum.all?(active_filters, &(&1 in categories))
    end)
  end

  @doc """
  Checks if a unit matches the given filter key.
  """
  def unit_matches_filter?(unit, filter_key) do
    categories = unit.categories || []
    filter_key in categories
  end

  # ============================================================================
  # Styling Helpers
  # ============================================================================

  @doc """
  Returns the background CSS class for a faction's unit icons.
  """
  def faction_bg_class(faction) do
    case faction do
      "UEF" -> "unit-bg-uef"
      "CYBRAN" -> "unit-bg-cybran"
      "AEON" -> "unit-bg-aeon"
      "SERAPHIM" -> "unit-bg-seraphim"
      _ -> "unit-bg-uef"
    end
  end

  @doc """
  Returns the color theme class for a faction (for tabs, badges, etc).
  """
  def faction_color_class(faction) do
    case faction do
      "UEF" -> "blue"
      "CYBRAN" -> "red"
      "AEON" -> "emerald"
      "SERAPHIM" -> "violet"
      _ -> "gray"
    end
  end

  @doc """
  Returns the badge color classes for a faction.
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
  Returns the tech level (1-4) for a unit based on its categories.
  """
  def get_tech_level(unit) do
    categories = unit.categories || []

    cond do
      "TECH1" in categories -> 1
      "TECH2" in categories -> 2
      "TECH3" in categories -> 3
      "EXPERIMENTAL" in categories -> 4
      true -> 1
    end
  end

  @doc """
  Returns the tech level badge text for a unit.
  """
  def tech_badge(unit) do
    case get_tech_level(unit) do
      1 -> "T1"
      2 -> "T2"
      3 -> "T3"
      4 -> "EXP"
    end
  end

  # ============================================================================
  # Unit Display Formatting
  # ============================================================================

  # Units that exist at multiple tech levels - need tier prefix
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

  # Descriptions that should be standardized across factions
  @standardized_descriptions [
    "Mass Extractor",
    "Mass Fabricator",
    "Energy Generator",
    "Hydrocarbon Power Plant"
  ]

  @doc """
  Formats a unit's display name with optional tier prefix.

  For multi-tier units (e.g., Mass Extractor), adds "T1 ", "T2 ", etc. prefix.
  For standardized units, uses the description instead of faction-specific name.
  """
  def format_unit_display_name(unit) do
    display_name = get_standardized_display_name(unit)
    tier_prefix = get_tier_prefix(unit)
    "#{tier_prefix}#{display_name}"
  end

  defp get_standardized_display_name(unit) do
    description = unit.description || "Unknown"

    if description in @standardized_descriptions do
      description
    else
      unit.name || description
    end
  end

  defp get_tier_prefix(unit) do
    description = unit.description || ""

    if description in @multi_tier_units do
      case get_tech_level(unit) do
        1 -> "T1 "
        2 -> "T2 "
        3 -> "T3 "
        4 -> "EXP "
        _ -> ""
      end
    else
      ""
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

  # ============================================================================
  # Selection Helpers
  # ============================================================================

  @doc """
  Checks if a unit is selected from a list of selected units.
  """
  def unit_selected?(selected_units, unit_id) when is_list(selected_units) do
    Enum.any?(selected_units, &(&1.unit_id == unit_id))
  end

  @doc """
  Finds a unit by its unit_id from a list of units.
  """
  def find_unit(units, unit_id) do
    Enum.find(units, &(&1.unit_id == unit_id))
  end

  @doc """
  Groups units by faction.
  """
  def group_units_by_faction(units) do
    units
    |> Enum.group_by(& &1.faction)
    |> Enum.map(fn {faction, faction_units} ->
      {faction, Enum.sort_by(faction_units, & &1.unit_id)}
    end)
    |> Enum.into(%{})
  end

  # ============================================================================
  # Style Helpers (for consistent UI across components)
  # ============================================================================

  @doc """
  Returns base CSS classes for filter buttons.

  ## Options

    * `:size` - :sm (default) or :xs
    * `:radius` - :md (default) or :lg
  """
  def filter_button_base_classes(opts \\ []) do
    size = Keyword.get(opts, :size, :sm)
    radius = Keyword.get(opts, :radius, :md)

    size_class =
      case size do
        :xs -> "text-xs"
        _ -> "text-sm"
      end

    radius_class =
      case radius do
        :lg -> "rounded-lg"
        _ -> "rounded"
      end

    "px-3 py-1.5 #{radius_class} #{size_class} font-medium transition-all"
  end

  @doc """
  Returns CSS classes for an active filter button.
  """
  def filter_button_active_classes(_opts \\ []) do
    "bg-indigo-500 text-white shadow-md"
  end

  @doc """
  Returns CSS classes for an inactive filter button.

  ## Options

    * `:variant` - :default (gray, for modals) or :light (white, for inline panels)
  """
  def filter_button_inactive_classes(opts \\ []) do
    variant = Keyword.get(opts, :variant, :default)

    case variant do
      :light -> "bg-white/90 text-gray-700 hover:bg-white hover:shadow"
      _ -> "bg-base-200 text-base-content hover:bg-base-300"
    end
  end

  @doc """
  Returns CSS classes for the Eco Only filter button.

  ## Options

    * `:active` - boolean
  """
  def eco_filter_button_classes(active, opts \\ []) do
    base = filter_button_base_classes(opts) <> " flex items-center gap-1.5"

    state =
      if active do
        "bg-emerald-500 text-white shadow-md"
      else
        "bg-base-200 text-base-content hover:bg-base-300"
      end

    "#{base} #{state}"
  end

  @doc """
  Returns CSS classes for the Clear Filters button.

  ## Options

    * `:size` - :sm (default) or :xs
    * `:radius` - :md (default) or :lg
    * `:variant` - :default or :inline (no ml-auto)
  """
  def clear_button_classes(opts \\ []) do
    size = Keyword.get(opts, :size, :sm)
    radius = Keyword.get(opts, :radius, :md)
    variant = Keyword.get(opts, :variant, :default)

    size_class =
      case size do
        :xs -> "text-xs"
        _ -> "text-sm"
      end

    radius_class =
      case radius do
        :lg -> "rounded-lg"
        _ -> "rounded"
      end

    position_class = if variant == :inline, do: "", else: "ml-auto"

    "#{position_class} px-3 py-1.5 #{radius_class} #{size_class} font-medium bg-gray-500/50 text-white hover:bg-gray-500/70 transition-all"
  end

  @doc """
  Returns CSS classes for faction pill buttons.

  ## Options

    * `:active` - boolean
  """
  def faction_pill_classes(faction, active, _opts \\ []) do
    base = "flex-1 py-2 px-4 text-sm font-medium rounded-lg transition-all"

    color =
      case {faction, active} do
        {_, true} ->
          case faction do
            "UEF" -> "bg-blue-500 text-white shadow-md"
            "CYBRAN" -> "bg-red-500 text-white shadow-md"
            "AEON" -> "bg-emerald-500 text-white shadow-md"
            "SERAPHIM" -> "bg-violet-500 text-white shadow-md"
            _ -> "bg-indigo-500 text-white shadow-md"
          end

        {_, false} ->
          "bg-base-100 text-base-content hover:bg-base-300"
      end

    "#{base} #{color}"
  end

  @doc """
  Returns CSS classes for faction tab buttons.

  ## Options

    * `:active` - boolean
  """
  def faction_tab_classes(faction, active, _opts \\ []) do
    base =
      "whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm capitalize transition-colors"

    color =
      case {faction, active} do
        {"UEF", true} -> "border-blue-500 text-blue-600"
        {"CYBRAN", true} -> "border-red-500 text-red-600"
        {"AEON", true} -> "border-emerald-500 text-emerald-600"
        {"SERAPHIM", true} -> "border-violet-500 text-violet-600"
        {_, true} -> "border-indigo-500 text-indigo-600"
        {_, false} -> "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
      end

    "#{base} #{color}"
  end
end
