defmodule FafCnWeb.EcoWorkflow.Handlers.LiveFlowEvents do
  @moduledoc """
  Handles LiveFlow-specific events: connections, selections, viewport changes, etc.
  """

  import Phoenix.Component

  alias LiveFlow.{State, Edge}

  @doc """
  Handle edge changes from LiveFlow (removals only).
  """
  def handle_edge_change(socket, changes) do
    flow =
      Enum.reduce(changes, socket.assigns.flow, fn
        %{"type" => "remove", "id" => id}, acc -> State.remove_edge(acc, id)
        _change, acc -> acc
      end)

    socket
    |> assign(flow: flow)
    |> mark_workflow_dirty()
    |> maybe_trigger_auto_save()
  end

  @doc """
  Handle connection end from LiveFlow (new edge created).
  """
  def handle_connect_end(socket, params) do
    source = params["source"]
    target = params["target"]

    if source && target && source != target do
      edge_id = "e-#{System.unique_integer([:positive])}"

      edge =
        Edge.new(edge_id, source, target,
          source_handle: params["source_handle"],
          target_handle: params["target_handle"],
          marker_end: %{type: :arrow_closed, color: "#64748b"}
        )

      flow = State.add_edge(socket.assigns.flow, edge)

      socket
      |> assign(flow: flow)
      |> mark_workflow_dirty()
      |> maybe_trigger_auto_save()
    else
      socket
    end
  end

  @doc """
  Handle selection change from LiveFlow.
  """
  def handle_selection_change(socket, node_ids, edge_ids) do
    flow =
      socket.assigns.flow
      |> Map.put(:selected_nodes, MapSet.new(node_ids))
      |> Map.put(:selected_edges, MapSet.new(edge_ids))

    nodes =
      Enum.reduce(flow.nodes, %{}, fn {id, node}, acc ->
        Map.put(acc, id, %{node | selected: id in node_ids})
      end)

    edges =
      Enum.reduce(flow.edges, %{}, fn {id, edge}, acc ->
        Map.put(acc, id, %{edge | selected: id in edge_ids})
      end)

    flow = %{flow | nodes: nodes, edges: edges}
    assign(socket, flow: flow)
  end

  @doc """
  Handle delete selected from LiveFlow.
  """
  def handle_delete_selected(socket, default_unit) do
    flow = State.delete_selected(socket.assigns.flow)
    # Prevent deletion of initial node
    flow = ensure_initial_node(flow, default_unit)
    assign(socket, flow: flow)
  end

  @doc """
  Handle viewport change from LiveFlow.
  """
  def handle_viewport_change(socket, params) do
    flow = State.update_viewport(socket.assigns.flow, params)
    assign(socket, flow: flow)
  end

  # ===== Private Helpers =====

  defp ensure_initial_node(flow, _default_unit) do
    if Map.has_key?(flow.nodes, "initial") do
      flow
    else
      # Recreate initial node if it was deleted
      alias LiveFlow.{Node, Handle}

      initial_node =
        Node.new(
          "initial",
          %{x: 50, y: 150},
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

      State.add_node(flow, initial_node)
    end
  end

  defp mark_workflow_dirty(socket) do
    assign(socket, workflow_dirty: true)
  end

  defp maybe_trigger_auto_save(socket) do
    if socket.assigns.workflow_id && socket.assigns.current_user do
      # Cancel existing timer if any
      if socket.assigns.save_debounce_timer do
        Process.cancel_timer(socket.assigns.save_debounce_timer)
      end

      # Set new timer for 2 seconds
      timer = Process.send_after(self(), :auto_save_workflow, 2000)
      assign(socket, save_debounce_timer: timer, workflow_saving: true)
    else
      socket
    end
  end
end
