defmodule FafCnWeb.EcoWorkflowLive do
  @moduledoc """
  Eco Workflow - Visual workflow builder for economy analysis.
  
  Inspired by LiveFlow's Pipeline Builder, this provides a canvas-based interface
  where users can build computation graphs using drag-and-drop nodes.
  """
  use FafCnWeb, :live_view

  alias LiveFlow.{State, Node, Edge, History, Clipboard}
  alias LiveFlow.Handle
  alias LiveFlow.Validation
  on_mount {FafCnWeb.UserAuth, :mount_current_user}

  @impl true
  def mount(_params, _session, socket) do
    flow = create_demo_flow()

    {:ok,
     assign(socket,
       page_title: "Eco Workflow",
       flow: flow,
       history: History.new(),
       clipboard: Clipboard.new(),
       node_types: %{
         fetch: &fetch_node/1,
         filter: &filter_node/1,
         compute: &compute_node/1,
         output: &output_node/1
       },
       lf_theme: nil
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="h-[calc(100vh-64px)] flex flex-col">
        <%!-- Toolbar Header --%>
        <div class="p-4 bg-base-200 border-b border-base-300">
          <div class="flex items-center justify-between">
            <div>
              <h1 class="text-2xl font-bold">Eco Workflow</h1>
              <p class="text-sm text-base-content/70">
                Build visual workflows for economy analysis
              </p>
            </div>
            <div class="flex items-center gap-2">
              <button class="btn btn-sm btn-primary" phx-click="add_fetch_node">
                <.icon name="hero-cloud-arrow-down" class="w-4 h-4 mr-1" />
                Fetch
              </button>
              <button class="btn btn-sm btn-secondary" phx-click="add_filter_node">
                <.icon name="hero-funnel" class="w-4 h-4 mr-1" />
                Filter
              </button>
              <button class="btn btn-sm btn-accent" phx-click="add_compute_node">
                <.icon name="hero-calculator" class="w-4 h-4 mr-1" />
                Compute
              </button>
              <div class="divider divider-horizontal mx-1"></div>
              <button class="btn btn-sm" phx-click="reset_flow">
                Reset
              </button>
              <button class="btn btn-sm" phx-click="fit_view">
                Fit View
              </button>
              <button class="btn btn-sm btn-info" phx-click={JS.dispatch("lf:auto-layout", to: "#eco-workflow-flow")}>
                Auto Layout
              </button>
              <div class="divider divider-horizontal mx-1"></div>
              <button class="btn btn-sm btn-outline" phx-click="export_json">
                Export
              </button>
              <button
                class="btn btn-sm btn-outline"
                onclick="document.getElementById('import-file-input').click()"
              >
                Import
              </button>
              <input
                type="file"
                id="import-file-input"
                accept=".json"
                class="hidden"
                phx-hook="FileImport"
              />
            </div>
          </div>
        </div>

        <%!-- Workflow Canvas --%>
        <div class="flex-1 relative">
          <.live_component
            module={LiveFlow.Components.Flow}
            id="eco-workflow-flow"
            flow={@flow}
            opts={%{
              controls: true,
              minimap: true,
              background: :dots,
              fit_view_on_init: true,
              snap_to_grid: true,
              snap_grid: {20, 20},
              theme: @lf_theme,
              helper_lines: true
            }}
            node_types={@node_types}
          />
        </div>

        <%!-- Footer Stats --%>
        <div class="p-3 bg-base-200 border-t border-base-300">
          <div class="flex items-center justify-between text-sm">
            <div>
              <span class="font-medium">Nodes:</span> {map_size(@flow.nodes)} |
              <span class="font-medium">Edges:</span> {map_size(@flow.edges)} |
              <span class="font-medium">Undo:</span> {History.undo_count(@history)} |
              <span class="font-medium">Redo:</span> {History.redo_count(@history)}
            </div>
            <div class="text-xs text-base-content/60">
              Ctrl+C copy | Ctrl+V paste | Ctrl+Z undo | Ctrl+Shift+Z redo | ? for help
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # ===== Custom Node Function Components =====

  defp fetch_node(assigns) do
    source = Map.get(assigns.node.data, :source, "Stock API")
    symbol = Map.get(assigns.node.data, :symbol, "AAPL")

    assigns =
      assigns
      |> assign(:source, source)
      |> assign(:symbol, symbol)

    ~H"""
    <div class="min-w-[180px] bg-blue-50 border-t-4 border-blue-500 rounded-lg p-3 shadow-sm">
      <div class="flex items-center gap-2 text-blue-700 font-semibold text-sm">
        <.icon name="hero-cloud-arrow-down" class="w-4 h-4" />
        Fetch Data
      </div>
      <div class="text-xs text-gray-600 mt-1">
        {@source} · {@symbol}
      </div>
    </div>
    """
  end

  defp filter_node(assigns) do
    condition = Map.get(assigns.node.data, :condition, "Price > 100")

    assigns = assign(assigns, :condition, condition)

    ~H"""
    <div class="min-w-[180px] bg-purple-50 border-t-4 border-purple-500 rounded-lg p-3 shadow-sm">
      <div class="flex items-center gap-2 text-purple-700 font-semibold text-sm">
        <.icon name="hero-funnel" class="w-4 h-4" />
        Filter
      </div>
      <div class="text-xs text-gray-600 mt-1">
        {@condition}
      </div>
    </div>
    """
  end

  defp compute_node(assigns) do
    operation = Map.get(assigns.node.data, :operation, "MA(20)")

    assigns = assign(assigns, :operation, operation)

    ~H"""
    <div class="min-w-[180px] bg-amber-50 border-t-4 border-amber-500 rounded-lg p-3 shadow-sm">
      <div class="flex items-center gap-2 text-amber-700 font-semibold text-sm">
        <.icon name="hero-calculator" class="w-4 h-4" />
        Compute
      </div>
      <div class="text-xs text-gray-600 mt-1">
        {@operation}
      </div>
    </div>
    """
  end

  defp output_node(assigns) do
    format = Map.get(assigns.node.data, :format, "PDF Report")

    assigns = assign(assigns, :format, format)

    ~H"""
    <div class="min-w-[180px] bg-green-50 border-t-4 border-green-500 rounded-lg p-3 shadow-sm">
      <div class="flex items-center gap-2 text-green-700 font-semibold text-sm">
        <.icon name="hero-document-text" class="w-4 h-4" />
        Output
      </div>
      <div class="text-xs text-gray-600 mt-1">
        {@format}
      </div>
    </div>
    """
  end

  # ===== Event Handlers =====

  @impl true
  def handle_event("add_fetch_node", _params, socket) do
    n = map_size(socket.assigns.flow.nodes) + 1

    node =
      Node.new("fetch-#{n}", %{x: 100 + rem(n, 4) * 200, y: 100 + div(n, 4) * 120},
        %{source: "Yahoo Finance", symbol: "AAPL"},
        type: :fetch,
        handles: [Handle.source(:right)]
      )

    history = History.push(socket.assigns.history, socket.assigns.flow)
    flow = State.add_node(socket.assigns.flow, node)
    {:noreply, assign(socket, flow: flow, history: history)}
  end

  @impl true
  def handle_event("add_filter_node", _params, socket) do
    n = map_size(socket.assigns.flow.nodes) + 1

    node =
      Node.new("filter-#{n}", %{x: 100 + rem(n, 4) * 200, y: 100 + div(n, 4) * 120},
        %{condition: "RSI < 30 (Oversold)"},
        type: :filter,
        handles: [Handle.target(:left), Handle.source(:right)]
      )

    history = History.push(socket.assigns.history, socket.assigns.flow)
    flow = State.add_node(socket.assigns.flow, node)
    {:noreply, assign(socket, flow: flow, history: history)}
  end

  @impl true
  def handle_event("add_compute_node", _params, socket) do
    n = map_size(socket.assigns.flow.nodes) + 1

    node =
      Node.new("compute-#{n}", %{x: 100 + rem(n, 4) * 200, y: 100 + div(n, 4) * 120},
        %{operation: "Bollinger Bands"},
        type: :compute,
        handles: [Handle.target(:left), Handle.source(:right)]
      )

    history = History.push(socket.assigns.history, socket.assigns.flow)
    flow = State.add_node(socket.assigns.flow, node)
    {:noreply, assign(socket, flow: flow, history: history)}
  end

  @impl true
  def handle_event("reset_flow", _params, socket) do
    {:noreply, assign(socket, flow: create_demo_flow(), history: History.new(), clipboard: Clipboard.new())}
  end

  @impl true
  def handle_event("export_json", _params, socket) do
    json = LiveFlow.Serializer.to_json(socket.assigns.flow)
    {:noreply, push_event(socket, "lf:download_file", %{content: json, filename: "eco_workflow.json", type: "application/json"})}
  end

  @impl true
  def handle_event("import_json", %{"content" => content}, socket) do
    case LiveFlow.Serializer.from_json(content) do
      {:ok, flow} ->
        history = History.push(socket.assigns.history, socket.assigns.flow)
        {:noreply, assign(socket, flow: flow, history: history)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Import failed: #{reason}")}
    end
  end

  @impl true
  def handle_event("fit_view", _params, socket) do
    {:noreply, push_event(socket, "lf:fit_view", %{padding: 0.1, duration: 200})}
  end

  # LiveFlow event handlers

  @impl true
  def handle_event("lf:node_change", %{"changes" => changes}, socket) do
    history =
      Enum.reduce(changes, socket.assigns.history, fn change, acc ->
        maybe_push_history_for_drag(acc, socket.assigns.flow, change)
      end)

    flow =
      Enum.reduce(changes, socket.assigns.flow, fn change, acc ->
        apply_node_change(acc, change)
      end)

    {:noreply, assign(socket, flow: flow, history: history)}
  end

  @impl true
  def handle_event("lf:connect_end", params, socket) do
    case Validation.Connection.validate_and_create(socket.assigns.flow, params) do
      {:ok, edge} ->
        history = History.push(socket.assigns.history, socket.assigns.flow)
        flow = State.add_edge(socket.assigns.flow, edge)
        {:noreply, assign(socket, flow: flow, history: history)}

      {:error, _reason} ->
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
    history = History.push(socket.assigns.history, socket.assigns.flow)
    flow = State.delete_selected(socket.assigns.flow)
    {:noreply, assign(socket, flow: flow, history: history)}
  end

  @impl true
  def handle_event("lf:edge_change", %{"changes" => changes}, socket) do
    has_removes = Enum.any?(changes, &(&1["type"] == "remove"))

    history =
      if has_removes,
        do: History.push(socket.assigns.history, socket.assigns.flow),
        else: socket.assigns.history

    flow =
      Enum.reduce(changes, socket.assigns.flow, fn
        %{"type" => "remove", "id" => id}, acc -> State.remove_edge(acc, id)
        _change, acc -> acc
      end)

    {:noreply, assign(socket, flow: flow, history: history)}
  end

  @impl true
  def handle_event("lf:viewport_change", params, socket) do
    flow = State.update_viewport(socket.assigns.flow, params)
    {:noreply, assign(socket, flow: flow)}
  end

  @impl true
  def handle_event("lf:copy", _params, socket) do
    clipboard = Clipboard.copy(socket.assigns.clipboard, socket.assigns.flow)
    {:noreply, assign(socket, clipboard: clipboard)}
  end

  @impl true
  def handle_event("lf:cut", _params, socket) do
    history = History.push(socket.assigns.history, socket.assigns.flow)
    {clipboard, flow} = Clipboard.cut(socket.assigns.clipboard, socket.assigns.flow)
    {:noreply, assign(socket, flow: flow, clipboard: clipboard, history: history)}
  end

  @impl true
  def handle_event("lf:paste", _params, socket) do
    case Clipboard.paste(socket.assigns.clipboard, socket.assigns.flow) do
      {:ok, flow, clipboard} ->
        history = History.push(socket.assigns.history, socket.assigns.flow)
        {:noreply, assign(socket, flow: flow, clipboard: clipboard, history: history)}

      :empty ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("lf:duplicate", _params, socket) do
    clipboard = Clipboard.copy(socket.assigns.clipboard, socket.assigns.flow)

    case Clipboard.paste(clipboard, socket.assigns.flow) do
      {:ok, flow, clipboard} ->
        history = History.push(socket.assigns.history, socket.assigns.flow)
        {:noreply, assign(socket, flow: flow, clipboard: clipboard, history: history)}

      :empty ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("lf:undo", _params, socket) do
    case History.undo(socket.assigns.history, socket.assigns.flow) do
      {:ok, flow, history} -> {:noreply, assign(socket, flow: flow, history: history)}
      :empty -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event("lf:redo", _params, socket) do
    case History.redo(socket.assigns.history, socket.assigns.flow) do
      {:ok, flow, history} -> {:noreply, assign(socket, flow: flow, history: history)}
      :empty -> {:noreply, socket}
    end
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

  defp maybe_push_history_for_drag(history, flow, %{"type" => "position", "id" => id} = change) do
    dragging = Map.get(change, "dragging", false)

    was_dragging =
      case Map.get(flow.nodes, id) do
        nil -> false
        node -> node.dragging
      end

    if dragging and not was_dragging do
      History.push(history, flow)
    else
      history
    end
  end

  defp maybe_push_history_for_drag(history, _flow, _change), do: history

  defp create_demo_flow do
    nodes = [
      # Fetch nodes
      Node.new("fetch-1", %{x: 50, y: 100},
        %{source: "Yahoo Finance", symbol: "AAPL"},
        type: :fetch,
        handles: [Handle.source(:right)]
      ),
      Node.new("fetch-2", %{x: 50, y: 250},
        %{source: "Alpha Vantage", symbol: "MSFT"},
        type: :fetch,
        handles: [Handle.source(:right)]
      ),

      # Filter nodes
      Node.new("filter-1", %{x: 300, y: 100},
        %{condition: "Volume > 1M"},
        type: :filter,
        handles: [Handle.target(:left), Handle.source(:right)]
      ),
      Node.new("filter-2", %{x: 300, y: 250},
        %{condition: "RSI < 30"},
        type: :filter,
        handles: [Handle.target(:left), Handle.source(:right)]
      ),

      # Compute node
      Node.new("compute-1", %{x: 550, y: 175},
        %{operation: "Correlation Analysis"},
        type: :compute,
        handles: [Handle.target(:left), Handle.source(:right)]
      ),

      # Output node
      Node.new("output-1", %{x: 800, y: 175},
        %{format: "PDF Report"},
        type: :output,
        handles: [Handle.target(:left)]
      )
    ]

    edges = [
      Edge.new("e1", "fetch-1", "filter-1"),
      Edge.new("e2", "fetch-2", "filter-2"),
      Edge.new("e3", "filter-1", "compute-1"),
      Edge.new("e4", "filter-2", "compute-1"),
      Edge.new("e5", "compute-1", "output-1")
    ]

    State.new(nodes: nodes, edges: edges)
  end
end
