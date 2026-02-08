defmodule FafCnWeb.EcoGuidesLive do
  @moduledoc """
  LiveView for Eco Guides - visualizing unit eco comparisons with icon-based selection.
  """
  use FafCnWeb, :live_view

  import FafCnWeb.EcoGuidesLive.Components

  alias FafCn.Units

  on_mount {FafCnWeb.UserAuth, :mount_current_user}

  @factions ["UEF", "CYBRAN", "AEON", "SERAPHIM"]

  # T1 Engineer unit IDs per faction (default base unit)
  @faction_engineers %{
    "UEF" => "UEL0105",
    "CYBRAN" => "URL0105",
    "AEON" => "UAL0105",
    "SERAPHIM" => "XSL0105"
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
        if unit_selected?(selected_units, unit_id) do
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
end
