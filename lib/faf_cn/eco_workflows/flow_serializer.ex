defmodule FafCn.EcoWorkflows.FlowSerializer do
  @moduledoc """
  Serializes and deserializes LiveFlow State to/from database format.

  This module handles the conversion between the runtime LiveFlow graph structure
  and the persistent database representation.

  Key features:
  - Saves and restores node positions for exact appearance preservation
  - Unit references stored by unit_id and resolved on load
  - Edge simulation data is NOT saved - simulation must be re-run after load
  """

  alias LiveFlow.{State, Node, Edge, Handle}
  alias FafCn.EcoWorkflows.{EcoWorkflow, EcoWorkflowNode, EcoWorkflowEdge}

  @doc """
  Serializes a LiveFlow State into attributes for creating/updating a workflow.

  ## Parameters
    - flow: The LiveFlow State to serialize
    - workflow_name: Name for the workflow
    - user_id: ID of the user creating the workflow

  ## Returns
    A map with keys: name, user_id, nodes, edges
  """
  def serialize(%State{} = flow, workflow_name, user_id) do
    nodes = serialize_nodes(flow.nodes)
    edges = serialize_edges(flow.edges)

    %{
      "name" => workflow_name,
      "user_id" => user_id,
      "nodes" => nodes,
      "edges" => edges
    }
  end

  @doc """
  Serializes just the node positions from a LiveFlow State.
  Used for lightweight position-only updates.

  ## Returns
    Map of node_id => %{x: float, y: float}
  """
  def serialize_positions(%State{} = flow) do
    flow.nodes
    |> Map.values()
    |> Enum.reject(&(&1.type == :initial))
    |> Enum.into(%{}, fn node ->
      {node.id, %{x: node.position.x, y: node.position.y}}
    end)
  end

  @doc """
  Deserializes an EcoWorkflow into a LiveFlow State.

  ## Parameters
    - workflow: The EcoWorkflow struct with preloaded nodes and edges
    - available_units: List of unit structs to resolve unit_id references

  ## Returns
    A LiveFlow State with restored positions
  """
  def deserialize(%EcoWorkflow{} = workflow, available_units) do
    # Build a lookup map for units by unit_id
    units_by_id =
      Enum.reduce(available_units, %{}, fn unit, acc ->
        Map.put(acc, unit.unit_id, unit)
      end)

    nodes = deserialize_nodes(workflow.nodes, units_by_id)
    edges = deserialize_edges(workflow.edges)

    State.new(nodes: nodes, edges: edges)
  end

  # --- Serialization ---

  defp serialize_nodes(nodes_map) when is_map(nodes_map) do
    nodes_map
    |> Map.values()
    |> Enum.reject(&(&1.type == :initial))
    |> Enum.map(&serialize_node/1)
  end

  defp serialize_node(%Node{} = node) do
    data = node.data || %{}
    unit = data[:unit]

    %{
      "node_id" => node.id,
      "node_type" => to_string(node.type),
      "unit_id" => unit && unit.unit_id,
      "quantity" => data[:quantity] || 1,
      "pos_x" => node.position.x,
      "pos_y" => node.position.y
    }
  end

  defp serialize_edges(edges_map) when is_map(edges_map) do
    edges_map
    |> Map.values()
    |> Enum.map(&serialize_edge/1)
  end

  defp serialize_edge(%Edge{} = edge) do
    %{
      "edge_id" => edge.id,
      "source_node_id" => edge.source,
      "target_node_id" => edge.target
    }
  end

  # --- Deserialization ---

  defp deserialize_nodes(db_nodes, units_by_id) when is_list(db_nodes) do
    # Create initial node at origin (will be repositioned by LiveFlow if needed)
    initial_node = create_initial_node()

    # Create unit nodes from database with restored positions
    unit_nodes =
      Enum.map(db_nodes, fn db_node ->
        deserialize_node(db_node, units_by_id)
      end)

    [initial_node | unit_nodes]
  end

  defp deserialize_node(%EcoWorkflowNode{} = db_node, units_by_id) do
    unit = db_node.unit_id && Map.get(units_by_id, db_node.unit_id)

    # Use saved position or default to origin
    pos_x = db_node.pos_x || 0.0
    pos_y = db_node.pos_y || 0.0

    Node.new(
      db_node.node_id,
      %{x: pos_x, y: pos_y},
      %{
        unit: unit,
        quantity: db_node.quantity || 1,
        finished_time: nil
      },
      type: :unit,
      handles: [Handle.target(:left), Handle.source(:right)]
    )
  end

  defp create_initial_node do
    Node.new(
      "initial",
      %{x: 50, y: 200},
      %{
        mass_in_storage: 650,
        energy_in_storage: 5000,
        mass_per_sec: 1.0,
        energy_per_sec: 20.0,
        build_power: 10
      },
      type: :initial,
      handles: [Handle.source(:right)],
      deletable: false
    )
  end

  defp deserialize_edges(db_edges) when is_list(db_edges) do
    Enum.map(db_edges, &deserialize_edge/1)
  end

  defp deserialize_edge(%EcoWorkflowEdge{} = db_edge) do
    Edge.new(
      db_edge.edge_id,
      db_edge.source_node_id,
      db_edge.target_node_id,
      source_handle: "right",
      target_handle: "left",
      marker_end: %{type: :arrow_closed, color: "#64748b"},
      data: %{
        mass_in_storage: 650,
        energy_in_storage: 5000,
        mass_per_sec: 1.0,
        energy_per_sec: 20.0,
        build_power: 10,
        elapsed_time: 0
      }
    )
  end
end
