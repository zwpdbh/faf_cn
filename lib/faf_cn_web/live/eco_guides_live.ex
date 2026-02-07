defmodule FafCnWeb.EcoGuidesLive do
  @moduledoc """
  LiveView for Eco Guides - visualizing unit eco comparisons with icon-based selection.
  """
  use FafCnWeb, :live_view

  alias FafCn.Units

  @factions ["UEF", "CYBRAN", "AEON", "SERAPHIM"]

  # T1 Engineer unit IDs per faction (default base unit)
  @faction_engineers %{
    "UEF" => "UEL0105",
    "CYBRAN" => "URL0105",
    "AEON" => "UAL0105",
    "SERAPHIM" => "XSL0105"
  }

  # Faction colors for UI styling
  @faction_colors %{
    "UEF" => "blue",
    "CYBRAN" => "red",
    "AEON" => "emerald",
    "SERAPHIM" => "violet"
  }

  @impl true
  def mount(_params, _session, socket) do
    units = Units.list_units()
    units_by_faction = group_units_by_faction(units)

    # Default to UEF faction
    selected_faction = "UEF"
    base_unit = find_unit(units, @faction_engineers[selected_faction])

    socket =
      socket
      |> assign(:page_title, "Eco Guides")
      |> assign(:factions, @factions)
      |> assign(:faction_engineers, @faction_engineers)
      |> assign(:faction_colors, @faction_colors)
      |> assign(:units, units)
      |> assign(:units_by_faction, units_by_faction)
      |> assign(:selected_faction, selected_faction)
      |> assign(:base_unit, base_unit)
      |> assign(:selected_units, [])

    {:ok, socket}
  end

  @impl true
  def handle_event("select_faction", %{"faction" => faction}, socket) do
    units = socket.assigns.units
    base_unit = find_unit(units, @faction_engineers[faction])

    {:noreply,
     socket
     |> assign(:selected_faction, faction)
     |> assign(:base_unit, base_unit)
     |> assign(:selected_units, [])}
  end

  @impl true
  def handle_event("toggle_unit", %{"unit_id" => unit_id}, socket) do
    selected_units = socket.assigns.selected_units
    unit = find_unit(socket.assigns.units, unit_id)

    # Don't allow selecting the base unit (engineer) again
    if unit_id == socket.assigns.base_unit.unit_id do
      {:noreply, socket}
    else
      new_selected_units =
        if Enum.any?(selected_units, &(&1.unit_id == unit_id)) do
          Enum.reject(selected_units, &(&1.unit_id == unit_id))
        else
          selected_units ++ [unit]
        end

      {:noreply,
       socket
       |> assign(:selected_units, new_selected_units)}
    end
  end

  @impl true
  def handle_event("clear_selections", _params, socket) do
    {:noreply,
     socket
     |> assign(:selected_units, [])}
  end

  defp group_units_by_faction(units) do
    units
    |> Enum.group_by(& &1.faction)
    |> Enum.map(fn {faction, faction_units} ->
      # Sort by unit_id to have consistent ordering
      {faction, Enum.sort_by(faction_units, & &1.unit_id)}
    end)
    |> Enum.into(%{})
  end

  defp find_unit(units, unit_id) do
    Enum.find(units, &(&1.unit_id == unit_id))
  end

  @doc """
  Checks if a unit is currently selected.
  """
  def unit_selected?(selected_units, unit_id) do
    Enum.any?(selected_units, &(&1.unit_id == unit_id))
  end

  @doc """
  Gets the icon class for a unit based on its strategic icon name.
  """
  def unit_icon_class(unit) do
    icon_name = get_in(unit.data, ["StrategicIconName"]) || "icon_land1_engineer"

    cond do
      String.contains?(icon_name, "engineer") -> "wrench"
      String.contains?(icon_name, "tank") -> "truck"
      String.contains?(icon_name, "bot") -> "user"
      String.contains?(icon_name, "air") -> "paper-airplane"
      String.contains?(icon_name, "ship") -> "bolt"
      String.contains?(icon_name, "sub") -> "eye-slash"
      String.contains?(icon_name, "structure") -> "home"
      String.contains?(icon_name, "commander") -> "star"
      String.contains?(icon_name, "anti") -> "shield-exclamation"
      String.contains?(icon_name, "artillery") -> "fire"
      String.contains?(icon_name, "missile") -> "rocket-launch"
      true -> "cube"
    end
  end

  @doc """
  Gets the background color class for a unit icon based on tech level and faction.
  """
  def unit_icon_bg_class(unit, faction_colors) do
    color = faction_colors[unit.faction] || "gray"

    tech_level = get_tech_level(unit)

    case tech_level do
      1 -> "bg-#{color}-500"
      2 -> "bg-#{color}-600"
      3 -> "bg-#{color}-700"
      _ -> "bg-#{color}-800"
    end
  end

  @doc """
  Gets the faction background class for unit icons (matching spooky-db style).
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
  Generates all comparison pairs for the selected units.
  Returns a list of {from_unit, to_unit, ratio} tuples.
  """
  def generate_comparisons(base_unit, selected_units) do
    all_units = [base_unit | selected_units]

    # Generate all unique pairs
    all_units
    |> Enum.with_index()
    |> Enum.flat_map(fn {unit_a, idx_a} ->
      all_units
      |> Enum.drop(idx_a + 1)
      |> Enum.with_index(idx_a + 1)
      |> Enum.map(fn {unit_b, idx_b} ->
        ratio = calculate_eco_ratio(unit_a, unit_b)
        {unit_a, idx_a, unit_b, idx_b, ratio}
      end)
    end)
  end

  @doc """
  Groups cross-comparisons by the "from" unit (base unit of comparison).
  Returns a list of {from_unit, from_idx, comparisons} tuples where comparisons
  is a list of {to_unit, to_idx, ratio} tuples.
  Groups are sorted by base unit mass cost (cheapest first).
  Comparisons within each group are sorted by mass cost (cheapest first).
  """
  def group_comparisons_by_base(comparisons) do
    comparisons
    |> Enum.group_by(fn {unit_a, idx_a, _, _, _} -> {unit_a, idx_a} end)
    |> Enum.map(fn {{unit_a, idx_a}, items} ->
      comparisons =
        items
        |> Enum.map(fn {_, _, unit_b, idx_b, ratio} ->
          {unit_b, idx_b, ratio}
        end)
        |> Enum.sort_by(fn {unit_b, _, _} -> unit_b.build_cost_mass end)

      {unit_a, idx_a, comparisons}
    end)
    |> Enum.sort_by(fn {unit_a, _, _} -> unit_a.build_cost_mass end)
  end

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
  Returns a label for the ratio display.
  """
  def ratio_label(nil), do: "?"
  def ratio_label(ratio), do: "#{ratio.mass}x"

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
  Calculates eco ratio between two units.
  Returns %{mass: ratio, energy: ratio, build_time: ratio}
  """
  def calculate_eco_ratio(base_unit, compare_unit)
      when is_nil(base_unit) or is_nil(compare_unit) do
    nil
  end

  def calculate_eco_ratio(base_unit, compare_unit) do
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

  @doc """
  Gets the letter label for a unit index (0 = Engineer, 1 = A, 2 = B, etc.)
  """
  def unit_letter_label(0), do: "Eng"
  def unit_letter_label(index), do: <<64 + index>>

  @doc """
  Returns the full comparison label between two units.
  """
  def comparison_label(from_idx, to_idx, _from_unit, _to_unit) do
    from_label = unit_letter_label(from_idx)
    to_label = unit_letter_label(to_idx)

    "#{to_label} = ? of #{from_label}"
  end
end
