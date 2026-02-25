defmodule FafCnWeb.EcoWorkflow.Handlers.Simulation do
  @moduledoc """
  Handles simulation operations: run simulation, clear simulation.
  """

  import Phoenix.Component

  alias FafCn.EcoEngine.BuildPower

  @doc """
  Run the simulation on the current workflow.
  """
  def run(socket) do
    flow = socket.assigns.flow

    # Get initial eco state from initial node
    initial_node = flow.nodes["initial"]
    initial_data = initial_node && initial_node.data

    initial_eco = %{
      mass_storage: initial_data[:mass_in_storage] || 650,
      energy_storage: initial_data[:energy_in_storage] || 5000,
      mass_per_sec: initial_data[:mass_per_sec] || 1.0,
      energy_per_sec: initial_data[:energy_per_sec] || 20.0,
      build_power: initial_data[:build_power] || 10
    }

    # Build topological order of units following edge connections
    build_order = get_build_order(flow)

    # Run simulation
    {updated_nodes, updated_edges, _final_eco} =
      simulate_build_order(flow, build_order, initial_eco)

    flow = %{flow | nodes: updated_nodes, edges: updated_edges}

    assign(socket, flow: flow, simulation_run: true)
  end

  @doc """
  Clear the simulation results.
  """
  def clear(socket) do
    flow = socket.assigns.flow

    # Clear finished times and restore deletable flag on all nodes
    updated_nodes =
      Enum.reduce(flow.nodes, %{}, fn {id, node}, acc ->
        updated_data = Map.put(node.data, :finished_time, nil)
        # Only non-initial nodes are deletable
        deletable = node.id != "initial"
        Map.put(acc, id, %{node | data: updated_data, deletable: deletable})
      end)

    # Clear simulation flag and restore deletable on edges
    updated_edges =
      Enum.reduce(flow.edges, %{}, fn {id, edge}, acc ->
        updated_data = Map.put(edge.data, :simulation_run, false)
        Map.put(acc, id, %{edge | data: updated_data, deletable: true, label: nil})
      end)

    flow = %{flow | nodes: updated_nodes, edges: updated_edges}
    assign(socket, flow: flow, simulation_run: false)
  end

  @doc """
  Build edge tooltips data for JS hook.
  Returns structured data with mass and energy as separate fields.
  """
  def build_edge_tooltips(edges, true = _simulation_run) do
    tooltips =
      Enum.reduce(edges, %{}, fn {id, edge}, acc ->
        data = edge.data || %{}

        if data[:simulation_run] do
          mass = data[:mass_per_sec] || 0
          energy = data[:energy_per_sec] || 0

          # Return structured data for the tooltip
          tooltip_data = %{
            mass: format_tooltip_value(mass),
            energy: format_tooltip_value(energy)
          }

          Map.put(acc, id, tooltip_data)
        else
          acc
        end
      end)

    Jason.encode!(tooltips)
  end

  def build_edge_tooltips(_edges, false = _simulation_run), do: "{}"

  @doc """
  Format eco data for the edge info modal.
  """
  def format_edge_data(edge_data) do
    %{
      mass_in_storage: format_modal_value(edge_data[:mass_in_storage] || 650),
      energy_in_storage: format_modal_value(edge_data[:energy_in_storage] || 5000),
      mass_per_sec: format_modal_value(edge_data[:mass_per_sec] || 1.0),
      energy_per_sec: format_modal_value(edge_data[:energy_per_sec] || 20.0),
      build_power: format_modal_value(edge_data[:build_power] || 10),
      elapsed_time: edge_data[:elapsed_time] || 0
    }
  end

  # ===== Simulation Helpers =====

  # Get build order by traversing the flow graph from initial node
  defp get_build_order(flow) do
    # Build adjacency list from edges
    adjacency =
      Enum.reduce(flow.edges, %{}, fn {_, edge}, acc ->
        source = edge.source
        target = edge.target
        Map.update(acc, source, [target], &[target | &1])
      end)

    # Start from initial node and traverse
    traverse_from("initial", adjacency, [])
    |> Enum.reverse()
    |> Enum.filter(&(&1 != "initial"))
  end

  # Traverse graph depth-first, avoiding cycles
  defp traverse_from(node_id, adjacency, visited) do
    if node_id in visited do
      visited
    else
      visited = [node_id | visited]
      neighbors = Map.get(adjacency, node_id, [])

      Enum.reduce(neighbors, visited, fn neighbor, acc ->
        traverse_from(neighbor, adjacency, acc)
      end)
    end
  end

  # Simulate building units in order
  defp simulate_build_order(flow, build_order, initial_eco) do
    # Find edge mapping: target_node_id -> edge_id
    edge_by_target =
      Enum.reduce(flow.edges, %{}, fn {id, edge}, acc ->
        Map.put(acc, edge.target, id)
      end)

    # Run simulation
    {nodes, edges, final_eco, _cumulative_time} =
      Enum.reduce(build_order, {flow.nodes, flow.edges, initial_eco, 0}, fn node_id,
                                                                            {nodes, edges, eco,
                                                                             cum_time} ->
        node = nodes[node_id]
        unit = node.data[:unit]
        quantity = node.data[:quantity] || 1

        if unit do
          # Calculate build metrics for this unit
          unit_stats = %{
            mass: unit.build_cost_mass * quantity,
            energy: unit.build_cost_energy * quantity,
            build_time: unit.build_time * quantity
          }

          production = %{
            mass: eco.mass_per_sec,
            energy: eco.energy_per_sec
          }

          storage = %{
            mass: eco.mass_storage,
            energy: eco.energy_storage
          }

          metrics =
            BuildPower.calculate_metrics(unit_stats, eco.build_power, production, storage)

          build_time = metrics.total_ticks
          new_cum_time = cum_time + build_time

          # Update node with finished time
          updated_node = %{
            node
            | data: Map.put(node.data, :finished_time, trunc(new_cum_time)),
              deletable: false
          }

          nodes = Map.put(nodes, node_id, updated_node)

          # Update edge with eco status at this point
          edge_id = edge_by_target[node_id]
          edges = update_edge_with_eco(edges, edge_id, eco, cum_time, metrics)

          # Update eco state after unit is built (add unit's eco contribution)
          new_eco = update_eco_after_build(eco, unit, quantity)

          {nodes, edges, new_eco, new_cum_time}
        else
          # No unit selected, skip
          {nodes, edges, eco, cum_time}
        end
      end)

    # Mark initial node as non-deletable
    nodes =
      Map.update!(nodes, "initial", fn node ->
        %{node | deletable: false}
      end)

    {nodes, edges, final_eco}
  end

  # Update edge with eco status data
  defp update_edge_with_eco(edges, nil, _eco, _cum_time, _metrics), do: edges

  defp update_edge_with_eco(edges, edge_id, eco, cum_time, metrics) do
    edge = edges[edge_id]

    edge_data = %{
      mass_in_storage: trunc(eco.mass_storage),
      energy_in_storage: trunc(eco.energy_storage),
      mass_per_sec: Float.round(eco.mass_per_sec, 1),
      energy_per_sec: Float.round(eco.energy_per_sec, 1),
      build_power: eco.build_power,
      elapsed_time: trunc(cum_time),
      simulation_run: true,
      tooltip_text:
        "Mass: -#{format_tooltip_value(metrics.drain_per_bp.mass * eco.build_power)}/s  |  Energy: -#{format_tooltip_value(metrics.drain_per_bp.energy * eco.build_power)}/s"
    }

    Map.put(edges, edge_id, %{edge | data: edge_data, deletable: false, label: nil})
  end

  # Update eco state after building a unit (add its BP, income, storage)
  defp update_eco_after_build(eco, unit, quantity) do
    # Handle case where unit.data might not be loaded (e.g., from list query)
    economy_data = fetch_unit_economy_data(unit)

    # Extract eco contributions from unit data
    build_rate = economy_data["BuildRate"] || 0
    energy_production = economy_data["ProductionPerSecondEnergy"] || 0
    mass_production = economy_data["ProductionPerSecondMass"] || 0
    energy_storage = economy_data["StorageEnergy"] || 0
    mass_storage = economy_data["StorageMass"] || 0

    %{
      mass_storage: eco.mass_storage + mass_storage * quantity,
      energy_storage: eco.energy_storage + energy_storage * quantity,
      mass_per_sec: eco.mass_per_sec + mass_production * quantity,
      energy_per_sec: eco.energy_per_sec + energy_production * quantity,
      build_power: eco.build_power + build_rate * quantity
    }
  end

  # Fetch economy data from unit, handling different data formats
  defp fetch_unit_economy_data(unit) do
    cond do
      # Ecto schema with data field loaded
      is_struct(unit, FafCn.Units.Unit) and is_map(unit.data) ->
        unit.data["Economy"] || %{}

      # Plain map with data field (preloaded)
      is_map(unit) and is_map(unit[:data]) ->
        unit[:data]["Economy"] || %{}

      # Plain map with data key but nil value
      is_map(unit) ->
        %{}
    end
  end

  # Format value for tooltip display (1 decimal place max)
  defp format_tooltip_value(value) when is_float(value) do
    if trunc(value) == value do
      trunc(value)
    else
      Float.round(value, 1)
    end
  end

  defp format_tooltip_value(value) when is_integer(value), do: value
  defp format_tooltip_value(_), do: 0

  # Format value for modal display (1 decimal place max, returns string)
  defp format_modal_value(value) when is_float(value) do
    if trunc(value) == value do
      "#{trunc(value)}"
    else
      "#{Float.round(value, 1)}"
    end
  end

  defp format_modal_value(value) when is_integer(value), do: "#{value}"
  defp format_modal_value(_), do: "0"
end
