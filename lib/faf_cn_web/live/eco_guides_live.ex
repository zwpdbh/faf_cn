defmodule FafCnWeb.EcoGuidesLive do
  @moduledoc """
  LiveView for Eco Guides - visualizing unit eco comparisons.
  """
  use FafCnWeb, :live_view

  alias FafCn.Units

  @factions ["UEF", "CYBRAN", "AEON", "SERAPHIM"]

  @impl true
  def mount(_params, _session, socket) do
    units = Units.list_units()

    socket =
      socket
      |> assign(:page_title, "Eco Guides")
      |> assign(:factions, @factions)
      |> assign(:units, units)
      |> assign(:base_unit, nil)
      |> assign(:compare_units, [nil, nil, nil])
      |> assign(:filtered_units, units)

    {:ok, socket}
  end

  @impl true
  def handle_event("select_base_unit", %{"unit_id" => unit_id}, socket) do
    base_unit = find_unit(socket.assigns.units, unit_id)

    {:noreply,
     socket
     |> assign(:base_unit, base_unit)}
  end

  @impl true
  def handle_event("select_compare_unit", %{"index" => index, "unit_id" => unit_id}, socket) do
    index = String.to_integer(index)
    compare_unit = find_unit(socket.assigns.units, unit_id)

    compare_units =
      List.replace_at(socket.assigns.compare_units, index, compare_unit)

    {:noreply,
     socket
     |> assign(:compare_units, compare_units)}
  end

  @impl true
  def handle_event("clear_base_unit", _params, socket) do
    {:noreply,
     socket
     |> assign(:base_unit, nil)}
  end

  @impl true
  def handle_event("clear_compare_unit", %{"index" => index}, socket) do
    index = String.to_integer(index)

    compare_units =
      List.replace_at(socket.assigns.compare_units, index, nil)

    {:noreply,
     socket
     |> assign(:compare_units, compare_units)}
  end

  @impl true
  def handle_event("add_compare_slot", _params, socket) do
    {:noreply,
     socket
     |> assign(:compare_units, socket.assigns.compare_units ++ [nil])}
  end

  @impl true
  def handle_event("remove_compare_slot", %{"index" => index}, socket) do
    index = String.to_integer(index)

    compare_units =
      socket.assigns.compare_units
      |> List.delete_at(index)

    {:noreply,
     socket
     |> assign(:compare_units, compare_units)}
  end

  defp find_unit(units, unit_id) do
    Enum.find(units, &(&1.unit_id == unit_id))
  end

  @doc """
  Generates all unique pairs from a list of items for cross-comparison.
  """
  def generate_pairs(list) when length(list) < 2, do: []

  def generate_pairs(list) do
    list
    |> Enum.with_index()
    |> Enum.flat_map(fn {item_a, idx_a} ->
      list
      |> Enum.drop(idx_a + 1)
      |> Enum.map(fn {item_b, idx_b} -> {{item_a, idx_a}, {item_b, idx_b}} end)
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
  def ratio_color_class(ratio) when ratio < 0.8, do: "text-green-600 font-medium"
  def ratio_color_class(ratio) when ratio > 1.5, do: "text-red-600 font-medium"
  def ratio_color_class(_ratio), do: "text-yellow-600 font-medium"

  @doc """
  Calculates eco ratio between two units.
  Returns {mass_ratio, energy_ratio, build_time_ratio}
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
  Formats a unit for display in the dropdown.
  """
  def format_unit_option(unit) do
    "#{unit.unit_id} - #{unit.description || unit.name || "Unknown"}"
  end
end
