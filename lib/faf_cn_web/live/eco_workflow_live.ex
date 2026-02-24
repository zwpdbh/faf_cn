defmodule FafCnWeb.EcoWorkflowLive do
  @moduledoc """
  Eco Workflow - Visual economy simulation builder for FAF (Forged Alliance Forever).

  Build and simulate economy flows with mass, energy, and build power nodes.
  """
  use FafCnWeb, :live_view

  alias LiveFlow.{State, Node, Edge, Handle}
  on_mount {FafCnWeb.UserAuth, :mount_current_user}

  @impl true
  def mount(_params, _session, socket) do
    flow = create_demo_flow()

    {:ok,
     assign(socket,
       page_title: "Eco Workflow",
       flow: flow,
       node_types: %{
         mass_storage: FafCnWeb.EcoWorkflow.MassStorageNode,
         power_storage: FafCnWeb.EcoWorkflow.PowerStorageNode,
         mass_rate: FafCnWeb.EcoWorkflow.MassRateNode,
         power_rate: FafCnWeb.EcoWorkflow.PowerRateNode,
         build_power: FafCnWeb.EcoWorkflow.BuildPowerNode
       }
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="h-[calc(100vh-64px)] flex flex-col">
        <%!-- Toolbar Header --%>
        <div class="p-4 bg-base-200 border-b border-base-300">
          <div class="flex items-center">
            <%!-- Left: Title --%>
            <div class="w-64 shrink-0">
              <h1 class="text-2xl font-bold">Eco Workflow</h1>
              <p class="text-sm text-base-content/70">
                Economy simulation for FAF
              </p>
            </div>

            <%!-- Center: Eco Parameter Buttons --%>
            <div class="flex-1 flex justify-center">
              <div class="flex items-center gap-2 bg-base-300/50 px-4 py-2 rounded-xl">
                <button class="btn btn-sm btn-primary" phx-click="add_mass_storage">
                  <.icon name="hero-cube" class="w-4 h-4 mr-1" /> Mass Storage
                </button>
                <button class="btn btn-sm btn-secondary" phx-click="add_power_storage">
                  <.icon name="hero-bolt" class="w-4 h-4 mr-1" /> Power Storage
                </button>
                <button class="btn btn-sm btn-accent" phx-click="add_mass_rate">
                  <.icon name="hero-arrow-trending-up" class="w-4 h-4 mr-1" /> Mass/sec
                </button>
                <button class="btn btn-sm btn-info" phx-click="add_power_rate">
                  <.icon name="hero-arrow-trending-down" class="w-4 h-4 mr-1" /> Power/sec
                </button>
                <button class="btn btn-sm btn-warning" phx-click="add_build_power">
                  <.icon name="hero-wrench" class="w-4 h-4 mr-1" /> Build Power
                </button>
              </div>
            </div>

            <%!-- Right: Action Buttons --%>
            <div class="w-64 shrink-0 flex justify-end items-center gap-2">
              <button class="btn btn-sm" phx-click="reset_flow">
                Reset
              </button>
              <button class="btn btn-sm" phx-click="fit_view">
                Fit View
              </button>
              <button
                class="btn btn-sm btn-success"
                phx-click={JS.dispatch("lf:auto-layout", to: "#eco-workflow-flow")}
              >
                Auto Layout
              </button>
            </div>
          </div>
        </div>

        <%!-- Workflow Canvas --%>
        <div class="flex-1 relative">
          <.live_component
            module={LiveFlow.Components.Flow}
            id="eco-workflow-flow"
            flow={@flow}
            opts={
              %{
                controls: true,
                minimap: true,
                background: :dots,
                fit_view_on_init: true,
                snap_to_grid: true,
                snap_grid: {20, 20}
              }
            }
            node_types={@node_types}
          />
        </div>

        <%!-- Footer Stats --%>
        <div class="p-3 bg-base-200 border-t border-base-300">
          <div class="flex items-center justify-between text-sm">
            <div>
              <span class="font-medium">Nodes:</span> {map_size(@flow.nodes)} |
              <span class="font-medium">Edges:</span> {map_size(@flow.edges)}
            </div>
            <div class="text-xs text-base-content/60">
              Drag to connect nodes | Click node to select | Delete to remove
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # ===== Event Handlers =====

  @impl true
  def handle_event("add_mass_storage", _params, socket) do
    n = System.unique_integer([:positive])

    node =
      Node.new(
        "mass-storage-#{n}",
        %{x: 100 + rem(n, 3) * 250, y: 100 + div(n, 3) * 150},
        %{
          label: "Mass Storage",
          value: 650,
          max: 650,
          unit: "mass"
        },
        type: :mass_storage,
        handles: [Handle.target(:left), Handle.source(:right)]
      )

    flow = State.add_node(socket.assigns.flow, node)
    {:noreply, assign(socket, flow: flow)}
  end

  @impl true
  def handle_event("add_power_storage", _params, socket) do
    n = System.unique_integer([:positive])

    node =
      Node.new(
        "power-storage-#{n}",
        %{x: 100 + rem(n, 3) * 250, y: 100 + div(n, 3) * 150},
        %{
          label: "Power Storage",
          value: 5000,
          max: 5000,
          unit: "energy"
        },
        type: :power_storage,
        handles: [Handle.target(:left), Handle.source(:right)]
      )

    flow = State.add_node(socket.assigns.flow, node)
    {:noreply, assign(socket, flow: flow)}
  end

  @impl true
  def handle_event("add_mass_rate", _params, socket) do
    n = System.unique_integer([:positive])

    node =
      Node.new(
        "mass-rate-#{n}",
        %{x: 100 + rem(n, 3) * 250, y: 100 + div(n, 3) * 150},
        %{
          label: "Mass Rate",
          income: 1.0,
          drain: 0.0,
          net: 1.0,
          unit: "mass/sec"
        },
        type: :mass_rate,
        handles: [Handle.target(:left), Handle.source(:right)]
      )

    flow = State.add_node(socket.assigns.flow, node)
    {:noreply, assign(socket, flow: flow)}
  end

  @impl true
  def handle_event("add_power_rate", _params, socket) do
    n = System.unique_integer([:positive])

    node =
      Node.new(
        "power-rate-#{n}",
        %{x: 100 + rem(n, 3) * 250, y: 100 + div(n, 3) * 150},
        %{
          label: "Power Rate",
          income: 20.0,
          drain: 10.0,
          net: 10.0,
          unit: "energy/sec"
        },
        type: :power_rate,
        handles: [Handle.target(:left), Handle.source(:right)]
      )

    flow = State.add_node(socket.assigns.flow, node)
    {:noreply, assign(socket, flow: flow)}
  end

  @impl true
  def handle_event("add_build_power", _params, socket) do
    n = System.unique_integer([:positive])

    node =
      Node.new(
        "build-power-#{n}",
        %{x: 100 + rem(n, 3) * 250, y: 100 + div(n, 3) * 150},
        %{
          label: "Build Power",
          value: 10,
          unit: "BP"
        },
        type: :build_power,
        handles: [Handle.target(:left), Handle.source(:right)]
      )

    flow = State.add_node(socket.assigns.flow, node)
    {:noreply, assign(socket, flow: flow)}
  end

  @impl true
  def handle_event("reset_flow", _params, socket) do
    {:noreply, assign(socket, flow: create_demo_flow())}
  end

  @impl true
  def handle_event("fit_view", _params, socket) do
    {:noreply, push_event(socket, "lf:fit_view", %{padding: 0.1, duration: 200})}
  end

  # LiveFlow event handlers

  @impl true
  def handle_event("lf:node_change", %{"changes" => changes}, socket) do
    flow =
      Enum.reduce(changes, socket.assigns.flow, fn change, acc ->
        apply_node_change(acc, change)
      end)

    {:noreply, assign(socket, flow: flow)}
  end

  @impl true
  def handle_event("lf:edge_change", %{"changes" => changes}, socket) do
    flow =
      Enum.reduce(changes, socket.assigns.flow, fn
        %{"type" => "remove", "id" => id}, acc -> State.remove_edge(acc, id)
        _change, acc -> acc
      end)

    {:noreply, assign(socket, flow: flow)}
  end

  @impl true
  def handle_event("lf:connect_end", params, socket) do
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
      {:noreply, assign(socket, flow: flow)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("lf:selection_change", %{"nodes" => node_ids, "edges" => edge_ids}, socket) do
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
    {:noreply, assign(socket, flow: flow)}
  end

  @impl true
  def handle_event("lf:delete_selected", _params, socket) do
    flow = State.delete_selected(socket.assigns.flow)
    {:noreply, assign(socket, flow: flow)}
  end

  @impl true
  def handle_event("lf:viewport_change", params, socket) do
    flow = State.update_viewport(socket.assigns.flow, params)
    {:noreply, assign(socket, flow: flow)}
  end

  @impl true
  def handle_event("lf:" <> _event, _params, socket) do
    {:noreply, socket}
  end

  # ===== Private Helpers =====

  defp apply_node_change(flow, %{"type" => "position", "id" => id, "position" => pos} = change) do
    case Map.get(flow.nodes, id) do
      nil ->
        flow

      node ->
        updated = %{
          node
          | position: %{x: pos["x"] / 1, y: pos["y"] / 1},
            dragging: Map.get(change, "dragging", false)
        }

        %{flow | nodes: Map.put(flow.nodes, id, updated)}
    end
  end

  defp apply_node_change(flow, %{"type" => "remove", "id" => id}) do
    State.remove_node(flow, id)
  end

  defp apply_node_change(flow, _change), do: flow

  defp create_demo_flow do
    nodes = [
      Node.new(
        "mass-storage-1",
        %{x: 50, y: 100},
        %{
          label: "Mass Storage",
          value: 650,
          max: 650,
          unit: "mass"
        },
        type: :mass_storage,
        handles: [Handle.target(:left), Handle.source(:right)]
      ),
      Node.new(
        "power-storage-1",
        %{x: 50, y: 250},
        %{
          label: "Power Storage",
          value: 5000,
          max: 5000,
          unit: "energy"
        },
        type: :power_storage,
        handles: [Handle.target(:left), Handle.source(:right)]
      ),
      Node.new(
        "mass-rate-1",
        %{x: 350, y: 100},
        %{
          label: "Mass Rate",
          income: 1.0,
          drain: 0.5,
          net: 0.5,
          unit: "mass/sec"
        },
        type: :mass_rate,
        handles: [Handle.target(:left), Handle.source(:right)]
      ),
      Node.new(
        "power-rate-1",
        %{x: 350, y: 250},
        %{
          label: "Power Rate",
          income: 20.0,
          drain: 15.0,
          net: 5.0,
          unit: "energy/sec"
        },
        type: :power_rate,
        handles: [Handle.target(:left), Handle.source(:right)]
      ),
      Node.new(
        "build-power-1",
        %{x: 650, y: 175},
        %{
          label: "Build Power",
          value: 10,
          unit: "BP"
        },
        type: :build_power,
        handles: [Handle.target(:left), Handle.source(:right)]
      )
    ]

    edges = [
      Edge.new("e1", "mass-storage-1", "mass-rate-1",
        marker_end: %{type: :arrow_closed, color: "#64748b"}
      ),
      Edge.new("e2", "power-storage-1", "power-rate-1",
        marker_end: %{type: :arrow_closed, color: "#64748b"}
      ),
      Edge.new("e3", "mass-rate-1", "build-power-1",
        marker_end: %{type: :arrow_closed, color: "#64748b"}
      ),
      Edge.new("e4", "power-rate-1", "build-power-1",
        marker_end: %{type: :arrow_closed, color: "#64748b"}
      )
    ]

    State.new(nodes: nodes, edges: edges)
  end
end
