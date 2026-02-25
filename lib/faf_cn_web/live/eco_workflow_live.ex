defmodule FafCnWeb.EcoWorkflowLive do
  @moduledoc """
  Eco Workflow - Visual economy simulation builder for FAF (Forged Alliance Forever).

  Build and simulate economy expansion by creating a workflow from an Initial Node
  to Unit Nodes representing FAF units to build.

  ## Architecture

  This LiveView delegates to several components and handlers:

  - **Components** (in `components/`):
    - `Header` - Toolbar with workflow controls
    - `Footer` - Stats display
    - `Canvas` - LiveFlow visualization wrapper
    - Modal LiveComponents - Save, Load, Rename, InitialSettings, EdgeInfo

  - **Handlers** (in `handlers/`):
    - `WorkflowManagement` - Save/load/rename/delete operations
    - `NodeOperations` - Add/update/remove nodes
    - `Simulation` - Run/clear simulation
    - `LiveFlowEvents` - LiveFlow event handling
  """
  use FafCnWeb, :live_view

  import FafCnWeb.FafUnitsComponents
  import FafCnWeb.EcoWorkflow.Components.{Footer, Canvas}
  alias FafCnWeb.EcoWorkflow.Components.Header

  alias LiveFlow.{State, Node, Edge, Handle}
  alias FafCn.Units
  alias FafCn.EcoWorkflows

  alias FafCnWeb.EcoWorkflow.Handlers.{
    WorkflowManagement,
    NodeOperations,
    Simulation,
    LiveFlowEvents
  }

  on_mount {FafCnWeb.UserAuth, :mount_current_user}

  @default_engineer_id "UEL0105"

  # Default workflow unit IDs
  @t3_engineer_id "UEL0309"
  @t3_pgen_id "UEB1301"
  @t3_mex_id "UEB1302"
  @fatboy_id "UEL0401"

  # Filter group constants from shared helpers
  @usage_filters FafCnWeb.FafUnitsHelpers.usage_filter_keys()
  @tech_filters FafCnWeb.FafUnitsHelpers.tech_filter_keys()

  @impl true
  def mount(_params, _session, socket) do
    # Load default T1 engineer unit
    default_unit = Units.get_unit_by_unit_id(@default_engineer_id)

    # Load available units for selection modal
    units = Units.list_units_for_eco_guides()
    units_by_faction = Enum.group_by(units, & &1.faction)

    # Load default workflow units
    t3_engineer = Units.get_unit_by_unit_id(@t3_engineer_id)
    t3_pgen = Units.get_unit_by_unit_id(@t3_pgen_id)
    t3_mex = Units.get_unit_by_unit_id(@t3_mex_id)
    fatboy = Units.get_unit_by_unit_id(@fatboy_id)

    workflow_units = %{
      t3_engineer: t3_engineer,
      t3_pgen: t3_pgen,
      t3_mex: t3_mex,
      fatboy: fatboy
    }

    flow = create_default_workflow(workflow_units)

    # Load user's saved workflows if logged in
    saved_workflows =
      if socket.assigns.current_user do
        EcoWorkflows.list_workflows(socket.assigns.current_user.id)
      else
        []
      end

    {:ok,
     assign(socket,
       page_title: "Eco Workflow",
       flow: flow,
       units: units,
       units_by_faction: units_by_faction,
       default_unit: default_unit,
       workflow_units: workflow_units,
       node_types: %{
         initial: FafCnWeb.EcoWorkflow.InitialNode,
         unit: FafCnWeb.EcoWorkflow.UnitNode
       },
       edge_types: %{
         default: FafCnWeb.EcoWorkflow.EdgeCard
       },
       # Workflow tracking
       workflow_id: nil,
       workflow_name: "Default Workflow",
       workflow_dirty: false,
       workflow_saving: false,
       # Modal states (simplified - components handle their own data)
       show_unit_selector: false,
       show_initial_settings: false,
       show_save_workflow: false,
       show_load_workflow: false,
       show_rename_workflow: false,
       show_edge_info: false,
       # Selection state
       selected_node_id: nil,
       selected_edge_id: nil,
       selected_faction: "UEF",
       current_unit_id: nil,
       unit_search: "",
       active_filters: [],
       show_eco_only: false,
       # Saved workflows
       saved_workflows: saved_workflows,
       # Simulation state
       simulation_run: false,
       # Auto-save timer
       save_debounce_timer: nil
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="h-[calc(100vh-64px)] flex flex-col">
        <%!-- Header Component --%>
        <Header.workflow_header
          current_user={@current_user}
          workflow_name={@workflow_name}
          workflow_dirty={@workflow_dirty}
          workflow_saving={@workflow_saving}
          workflow_id={@workflow_id}
          simulation_run={@simulation_run}
        />

        <%!-- Canvas Component --%>
        <.canvas
          flow={@flow}
          simulation_run={@simulation_run}
          node_types={@node_types}
          edge_types={@edge_types}
          edge_tooltips={Simulation.build_edge_tooltips(@flow.edges, @simulation_run)}
        />

        <%!-- Footer Component --%>
        <.footer flow={@flow} />
      </div>

      <%!-- Unit Selector Modal (from FafUnitsComponents) --%>
      <.unit_selector_modal
        show={@show_unit_selector}
        units_by_faction={@units_by_faction}
        selected_faction={@selected_faction}
        current_unit_id={@current_unit_id}
        active_filters={@active_filters}
        show_eco_only={@show_eco_only}
      />

      <%!-- LiveComponent Modals --%>
      <%= if @show_initial_settings do %>
        <.live_component
          module={FafCnWeb.EcoWorkflow.Components.InitialSettingsModal}
          id="initial-settings-modal"
          initial_data={get_initial_settings_form(@flow)}
        />
      <% end %>

      <%= if @show_edge_info do %>
        <.live_component
          module={FafCnWeb.EcoWorkflow.Components.EdgeInfoModal}
          id="edge-info-modal"
          edge={@flow.edges[@selected_edge_id]}
        />
      <% end %>

      <%= if @show_save_workflow do %>
        <.live_component
          module={FafCnWeb.EcoWorkflow.Components.SaveWorkflowModal}
          id="save-workflow-modal"
        />
      <% end %>

      <%= if @show_load_workflow do %>
        <.live_component
          module={FafCnWeb.EcoWorkflow.Components.LoadWorkflowModal}
          id="load-workflow-modal"
          workflows={@saved_workflows}
          current_workflow_id={@workflow_id}
          current_user={@current_user}
        />
      <% end %>

      <%= if @show_rename_workflow do %>
        <.live_component
          module={FafCnWeb.EcoWorkflow.Components.RenameWorkflowModal}
          id="rename-workflow-modal"
          current_name={@workflow_name}
        />
      <% end %>
    </Layouts.app>
    """
  end

  # ===== Event Handlers - Grouped by type =====

  # -- Node Operations --

  @impl true
  def handle_event("add_unit_node", _params, socket) do
    {:noreply, NodeOperations.add_unit_node(socket, socket.assigns.default_unit)}
  end

  @impl true
  def handle_event("increase_quantity", %{"node-id" => node_id}, socket) do
    {:noreply, NodeOperations.increase_quantity(socket, node_id)}
  end

  @impl true
  def handle_event("decrease_quantity", %{"node-id" => node_id}, socket) do
    {:noreply, NodeOperations.decrease_quantity(socket, node_id)}
  end

  @impl true
  def handle_event("open_unit_selector", %{"node-id" => node_id}, socket) do
    node = socket.assigns.flow.nodes[node_id]
    current_unit_id = node && node.data[:unit] && node.data[:unit].unit_id

    {:noreply,
     assign(socket,
       show_unit_selector: true,
       selected_node_id: node_id,
       current_unit_id: current_unit_id,
       selected_faction: "UEF",
       unit_search: "",
       active_filters: [],
       show_eco_only: false
     )}
  end

  @impl true
  def handle_event("close_unit_selector", _params, socket) do
    {:noreply,
     assign(socket,
       show_unit_selector: false,
       selected_node_id: nil,
       unit_search: ""
     )}
  end

  @impl true
  def handle_event("select_unit_for_node", %{"unit_id" => unit_id}, socket) do
    node_id = socket.assigns.selected_node_id

    {:noreply,
     NodeOperations.select_unit_for_node(socket, node_id, unit_id, socket.assigns.units)}
  end

  @impl true
  def handle_event("open_initial_settings", %{"node-id" => _node_id}, socket) do
    {:noreply, assign(socket, show_initial_settings: true)}
  end

  # -- Simulation Operations --

  @impl true
  def handle_event("run_simulation", _params, socket) do
    {:noreply, Simulation.run(socket)}
  end

  @impl true
  def handle_event("clear_simulation", _params, socket) do
    {:noreply, Simulation.clear(socket)}
  end

  @impl true
  def handle_event("show_edge_info", %{"edge_id" => edge_id}, socket) do
    {:noreply,
     assign(socket,
       show_edge_info: true,
       selected_edge_id: edge_id
     )}
  end

  # -- Workflow Management --

  @impl true
  def handle_event("open_save_workflow", _params, socket) do
    {:noreply, assign(socket, show_save_workflow: true)}
  end

  @impl true
  def handle_event("prompt_login", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Please log in to save workflows")
     |> push_navigate(to: ~p"/auth/github")}
  end

  @impl true
  def handle_event("quick_save_workflow", _params, socket) do
    {:noreply, WorkflowManagement.handle_quick_save(socket)}
  end

  @impl true
  def handle_event("open_load_workflow_modal", _params, socket) do
    saved_workflows = WorkflowManagement.list_workflows(socket)
    {:noreply, assign(socket, show_load_workflow: true, saved_workflows: saved_workflows)}
  end

  @impl true
  def handle_event("load_workflow", params, socket) do
    WorkflowManagement.handle_load(socket, params, socket.assigns.units)
  end

  @impl true
  def handle_event("open_rename_workflow", _params, socket) do
    {:noreply, assign(socket, show_rename_workflow: true)}
  end

  @impl true
  def handle_event("rename_workflow", params, socket) do
    {:noreply, WorkflowManagement.handle_rename(socket, params)}
  end

  @impl true
  def handle_event("delete_workflow", %{"workflow_id" => workflow_id}, socket) do
    {:noreply, WorkflowManagement.handle_delete(socket, workflow_id)}
  end

  @impl true
  def handle_event("reset_to_default", _params, socket) do
    flow = create_default_workflow(socket.assigns.workflow_units)

    {:noreply,
     assign(socket,
       flow: flow,
       simulation_run: false,
       workflow_id: nil,
       workflow_name: "Default Workflow",
       workflow_dirty: false
     )}
  end

  # -- UI Events --

  @impl true
  def handle_event("select_node", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_unit", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_eco_filter", _params, socket) do
    {:noreply, assign(socket, show_eco_only: !socket.assigns.show_eco_only)}
  end

  @impl true
  def handle_event("select_faction", %{"faction" => faction}, socket) do
    {:noreply, assign(socket, selected_faction: faction)}
  end

  @impl true
  def handle_event("toggle_filter", %{"filter" => filter_key}, socket) do
    active_filters = socket.assigns.active_filters

    new_filters =
      if filter_key in active_filters do
        List.delete(active_filters, filter_key)
      else
        group_filters =
          cond do
            filter_key in @usage_filters -> @usage_filters
            filter_key in @tech_filters -> @tech_filters
            true -> []
          end

        active_filters
        |> Enum.reject(&(&1 in group_filters))
        |> Kernel.++([filter_key])
      end

    {:noreply, assign(socket, active_filters: new_filters)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply, assign(socket, active_filters: [], show_eco_only: false)}
  end

  @impl true
  def handle_event("search_units", %{"value" => search}, socket) do
    {:noreply, assign(socket, unit_search: search)}
  end

  @impl true
  def handle_event("reset_flow", _params, socket) do
    flow = create_default_workflow(socket.assigns.workflow_units)
    {:noreply, assign(socket, flow: flow, simulation_run: false)}
  end

  @impl true
  def handle_event("fit_view", _params, socket) do
    {:noreply, push_event(socket, "lf:fit_view", %{padding: 0.1, duration: 200})}
  end

  # -- LiveFlow Events --

  @impl true
  def handle_event("lf:node_change", %{"changes" => changes}, socket) do
    {:noreply, NodeOperations.apply_node_changes(socket, changes)}
  end

  @impl true
  def handle_event("lf:edge_change", %{"changes" => changes}, socket) do
    {:noreply, LiveFlowEvents.handle_edge_change(socket, changes)}
  end

  @impl true
  def handle_event("lf:connect_end", params, socket) do
    {:noreply, LiveFlowEvents.handle_connect_end(socket, params)}
  end

  @impl true
  def handle_event("lf:selection_change", %{"nodes" => node_ids, "edges" => edge_ids}, socket) do
    {:noreply, LiveFlowEvents.handle_selection_change(socket, node_ids, edge_ids)}
  end

  @impl true
  def handle_event("lf:delete_selected", _params, socket) do
    {:noreply, LiveFlowEvents.handle_delete_selected(socket, socket.assigns.default_unit)}
  end

  @impl true
  def handle_event("lf:viewport_change", params, socket) do
    {:noreply, LiveFlowEvents.handle_viewport_change(socket, params)}
  end

  @impl true
  def handle_event("lf:" <> _event, _params, socket) do
    {:noreply, socket}
  end

  # ===== Info Handlers - Messages from LiveComponents =====

  @impl true
  def handle_info({:lf_node_click, node_id}, socket) do
    require Logger
    Logger.debug("[EcoWorkflow] Node clicked: #{node_id}")
    {:noreply, socket}
  end

  @impl true
  def handle_info(:auto_save_workflow, socket) do
    {:noreply, WorkflowManagement.handle_auto_save(socket)}
  end

  # -- Modal close messages --

  @impl true
  def handle_info({:close_modal, :save_workflow}, socket) do
    {:noreply, assign(socket, show_save_workflow: false, save_workflow_error: nil)}
  end

  @impl true
  def handle_info({:close_modal, :load_workflow}, socket) do
    {:noreply, assign(socket, show_load_workflow: false)}
  end

  @impl true
  def handle_info({:close_modal, :rename_workflow}, socket) do
    {:noreply, assign(socket, show_rename_workflow: false)}
  end

  @impl true
  def handle_info({:close_modal, :initial_settings}, socket) do
    {:noreply, assign(socket, show_initial_settings: false)}
  end

  @impl true
  def handle_info({:close_modal, :edge_info}, socket) do
    {:noreply, assign(socket, show_edge_info: false, selected_edge_id: nil)}
  end

  # -- Modal action messages --

  @impl true
  def handle_info({:save_workflow, name}, socket) do
    WorkflowManagement.handle_save(socket, %{"name" => name})
  end

  @impl true
  def handle_info({:load_workflow, workflow_id}, socket) do
    WorkflowManagement.handle_load(socket, %{"workflow_id" => workflow_id}, socket.assigns.units)
  end

  @impl true
  def handle_info({:rename_workflow, name}, socket) do
    {:noreply, WorkflowManagement.handle_rename(socket, %{"name" => name})}
  end

  @impl true
  def handle_info({:save_initial_settings, params}, socket) do
    {:noreply, NodeOperations.save_initial_settings(socket, params)}
  end

  # ===== Private Helpers =====

  defp get_initial_settings_form(flow) do
    NodeOperations.get_initial_settings_form(flow)
  end

  defp create_default_workflow(units) do
    # Initial eco state
    initial_eco = %{
      mass_in_storage: 650,
      energy_in_storage: 5000,
      mass_per_sec: 1.0,
      energy_per_sec: 20.0,
      build_power: 10
    }

    # Create initial node
    initial_node =
      Node.new(
        "initial",
        %{x: 50, y: 200},
        initial_eco,
        type: :initial,
        handles: [Handle.source(:right)],
        deletable: false
      )

    # Create workflow: initial -> 3x T3 Engineer -> T3 PGen -> T3 Mex -> Fatboy
    node_specs = [
      {"unit-t3-eng-1", units.t3_engineer, %{x: 250, y: 100}, 1},
      {"unit-t3-eng-2", units.t3_engineer, %{x: 400, y: 200}, 1},
      {"unit-t3-eng-3", units.t3_engineer, %{x: 550, y: 300}, 1},
      {"unit-t3-pgen", units.t3_pgen, %{x: 700, y: 200}, 1},
      {"unit-t3-mex", units.t3_mex, %{x: 850, y: 200}, 1},
      {"unit-fatboy", units.fatboy, %{x: 1000, y: 200}, 1}
    ]

    {unit_nodes, _} =
      Enum.map_reduce(node_specs, [], fn {id, unit, pos, qty}, acc ->
        node =
          Node.new(
            id,
            pos,
            %{unit: unit, quantity: qty, finished_time: nil},
            type: :unit,
            handles: [Handle.target(:left), Handle.source(:right)]
          )

        {node, [node | acc]}
      end)

    edge_specs = [
      {"e-initial", "initial", "unit-t3-eng-1"},
      {"e-eng-1", "unit-t3-eng-1", "unit-t3-eng-2"},
      {"e-eng-2", "unit-t3-eng-2", "unit-t3-eng-3"},
      {"e-eng-3", "unit-t3-eng-3", "unit-t3-pgen"},
      {"e-pgen", "unit-t3-pgen", "unit-t3-mex"},
      {"e-mex", "unit-t3-mex", "unit-fatboy"}
    ]

    edges =
      Enum.map(edge_specs, fn {id, source, target} ->
        Edge.new(id, source, target,
          source_handle: "right",
          target_handle: "left",
          marker_end: %{type: :arrow_closed, color: "#64748b"},
          data: %{
            mass_in_storage: initial_eco.mass_in_storage,
            energy_in_storage: initial_eco.energy_in_storage,
            mass_per_sec: initial_eco.mass_per_sec,
            energy_per_sec: initial_eco.energy_per_sec,
            build_power: initial_eco.build_power,
            elapsed_time: 0
          }
        )
      end)

    all_nodes = [initial_node | Enum.reverse(unit_nodes)]

    State.new(nodes: all_nodes, edges: edges)
  end
end
