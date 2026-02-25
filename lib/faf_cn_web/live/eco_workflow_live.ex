defmodule FafCnWeb.EcoWorkflowLive do
  @moduledoc """
  Eco Workflow - Visual economy simulation builder for FAF (Forged Alliance Forever).

  Build and simulate economy expansion by creating a workflow from an Initial Node
  to Unit Nodes representing FAF units to build.
  """
  use FafCnWeb, :live_view

  import FafCnWeb.FafUnitsComponents

  alias LiveFlow.{State, Node, Edge, Handle}
  alias FafCn.Units
  alias FafCn.EcoEngine.BuildPower
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
       # Modal state
       show_unit_selector: false,
       show_initial_settings: false,
       selected_node_id: nil,
       selected_faction: "UEF",
       current_unit_id: nil,
       unit_search: "",
       active_filters: [],
       show_eco_only: false,
       # Initial node settings form
       initial_settings_form: %{
         "mass_in_storage" => 650,
         "energy_in_storage" => 5000,
         "mass_per_sec" => 1.0,
         "energy_per_sec" => 20.0,
         "build_power" => 10
       },
       # Simulation state
       simulation_run: false,
       # Edge info modal state
       show_edge_info: false,
       selected_edge_id: nil
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
                Build order simulation for FAF
              </p>
            </div>

            <%!-- Center: Action Buttons --%>
            <div class="flex-1 flex justify-center">
              <div class="flex items-center gap-2 bg-base-300/50 px-4 py-2 rounded-xl">
                <button class="btn btn-sm btn-primary" phx-click="add_unit_node">
                  <.icon name="hero-plus" class="w-4 h-4 mr-1" /> Add Unit
                </button>
                <%= if @simulation_run do %>
                  <button class="btn btn-sm btn-warning" phx-click="clear_simulation">
                    <.icon name="hero-arrow-path" class="w-4 h-4 mr-1" /> Reset Simulation
                  </button>
                <% else %>
                  <button class="btn btn-sm btn-success" phx-click="run_simulation">
                    <.icon name="hero-play" class="w-4 h-4 mr-1" /> Run Simulation
                  </button>
                <% end %>
              </div>
            </div>

            <%!-- Right: Action Buttons --%>
            <div class="w-64 shrink-0 flex justify-end items-center gap-2">
              <button class="btn btn-sm" phx-click="reset_flow">
                <.icon name="hero-arrow-path" class="w-4 h-4 mr-1" /> Reset
              </button>
              <button class="btn btn-sm" phx-click="fit_view">
                <.icon name="hero-arrows-pointing-out" class="w-4 h-4 mr-1" /> Fit
              </button>
              <button
                class="btn btn-sm btn-info"
                phx-click={JS.dispatch("lf:auto-layout", to: "#eco-workflow-flow")}
              >
                <.icon name="hero-sparkles" class="w-4 h-4 mr-1" /> Auto
              </button>
            </div>
          </div>
        </div>

        <%!-- Workflow Canvas --%>
        <div
          class="flex-1 relative"
          id="eco-workflow-container"
          data-simulation-run={to_string(@simulation_run)}
          data-edge-tooltips={build_edge_tooltips(@flow.edges, @simulation_run)}
          phx-hook="EdgeInfo"
        >
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
                snap_grid: {20, 20},
                nodes_draggable: not @simulation_run,
                nodes_connectable: not @simulation_run,
                elements_selectable: true
              }
            }
            node_types={@node_types}
            edge_types={@edge_types}
          />
        </div>

        <%!-- Footer Stats --%>
        <div class="p-3 bg-base-200 border-t border-base-300">
          <div class="flex items-center justify-between text-sm">
            <div>
              <span class="font-medium">Units:</span> {count_unit_nodes(@flow)} |
              <span class="font-medium">Connections:</span> {map_size(@flow.edges)}
            </div>
            <div class="text-xs text-base-content/60">
              Drag from right handle to left handle to connect | Double-click unit to change | Delete to remove
            </div>
          </div>
        </div>
      </div>

      <%!-- Unit Selector Modal --%>
      <.unit_selector_modal
        show={@show_unit_selector}
        units_by_faction={@units_by_faction}
        selected_faction={@selected_faction}
        current_unit_id={@current_unit_id}
        active_filters={@active_filters}
        show_eco_only={@show_eco_only}
      />

      <%!-- Initial Node Settings Modal --%>
      <%= if @show_initial_settings do %>
        <.initial_settings_modal form={@initial_settings_form} />
      <% end %>

      <%!-- Edge Info Modal (Read-only eco stats) --%>
      <%= if @show_edge_info do %>
        <.edge_info_modal edge={@flow.edges[@selected_edge_id]} />
      <% end %>
    </Layouts.app>
    """
  end

  # ===== Components =====

  # Unit selector modal is now provided by FafUnitsComponents.unit_selector_modal/1

  defp initial_settings_modal(assigns) do
    ~H"""
    <div
      id="initial-settings-modal-backdrop"
      class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
      phx-click-away="close_initial_settings"
    >
      <.form
        for={@form}
        phx-submit="save_initial_settings"
        class="bg-base-100 rounded-xl shadow-2xl w-full max-w-md"
      >
        <%!-- Modal Header --%>
        <div class="p-4 border-b border-base-300 flex items-center justify-between">
          <h2 class="text-lg font-semibold">Initial Eco Settings</h2>
          <button
            class="btn btn-sm btn-ghost"
            phx-click="close_initial_settings"
          >
            <.icon name="hero-x-mark" class="w-5 h-5" />
          </button>
        </div>

        <%!-- Settings Form --%>
        <div class="p-6 space-y-4">
          <%!-- Storage Section --%>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="label">
                <span class="label-text flex items-center gap-1">
                  <.icon name="hero-cube" class="w-4 h-4 text-mass" /> Mass Storage
                </span>
              </label>
              <input
                type="number"
                name="mass_in_storage"
                value={@form["mass_in_storage"]}
                class="input input-bordered w-full"
                min="0"
              />
            </div>
            <div>
              <label class="label">
                <span class="label-text flex items-center gap-1">
                  <.icon name="hero-bolt" class="w-4 h-4 text-energy" /> Energy Storage
                </span>
              </label>
              <input
                type="number"
                name="energy_in_storage"
                value={@form["energy_in_storage"]}
                class="input input-bordered w-full"
                min="0"
              />
            </div>
          </div>

          <%!-- Income Section --%>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="label">
                <span class="label-text flex items-center gap-1">
                  <.icon name="hero-arrow-trending-up" class="w-4 h-4 text-mass" /> Mass/sec
                </span>
              </label>
              <input
                type="number"
                name="mass_per_sec"
                value={@form["mass_per_sec"]}
                class="input input-bordered w-full"
                min="0"
                step="0.1"
              />
            </div>
            <div>
              <label class="label">
                <span class="label-text flex items-center gap-1">
                  <.icon name="hero-arrow-trending-down" class="w-4 h-4 text-energy" /> Energy/sec
                </span>
              </label>
              <input
                type="number"
                name="energy_per_sec"
                value={@form["energy_per_sec"]}
                class="input input-bordered w-full"
                min="0"
                step="0.1"
              />
            </div>
          </div>

          <%!-- Build Power --%>
          <div>
            <label class="label">
              <span class="label-text flex items-center gap-1">
                <.icon name="hero-wrench" class="w-4 h-4 text-build" /> Build Power
              </span>
            </label>
            <input
              type="number"
              name="build_power"
              value={@form["build_power"]}
              class="input input-bordered w-full"
              min="0"
            />
          </div>
        </div>

        <%!-- Modal Footer --%>
        <div class="p-4 border-t border-base-300 flex justify-end gap-2">
          <button
            type="button"
            class="btn btn-ghost"
            phx-click="close_initial_settings"
          >
            Cancel
          </button>
          <button
            type="submit"
            class="btn btn-primary"
          >
            Save Changes
          </button>
        </div>
      </.form>
    </div>
    """
  end

  defp edge_info_modal(assigns) do
    edge = assigns.edge
    edge_data = edge && edge.data

    assigns =
      assigns
      |> assign(:mass_in_storage, format_modal_value(edge_data[:mass_in_storage] || 650))
      |> assign(:energy_in_storage, format_modal_value(edge_data[:energy_in_storage] || 5000))
      |> assign(:mass_per_sec, format_modal_value(edge_data[:mass_per_sec] || 1.0))
      |> assign(:energy_per_sec, format_modal_value(edge_data[:energy_per_sec] || 20.0))
      |> assign(:build_power, format_modal_value(edge_data[:build_power] || 10))
      |> assign(:elapsed_time, edge_data[:elapsed_time] || 0)

    ~H"""
    <div
      id="edge-info-modal-backdrop"
      class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
      phx-click-away="close_edge_info"
    >
      <div class="bg-base-100 rounded-xl shadow-2xl w-full max-w-md overflow-hidden">
        <%!-- Modal Header --%>
        <div class="p-4 border-b border-base-300 flex items-center justify-between bg-linear-to-r from-info/10 to-transparent">
          <div class="flex items-center gap-2">
            <.icon name="hero-information-circle" class="w-5 h-5 text-info" />
            <h2 class="text-lg font-semibold">Eco Statistics</h2>
          </div>
          <button
            class="btn btn-sm btn-ghost"
            phx-click="close_edge_info"
          >
            <.icon name="hero-x-mark" class="w-5 h-5" />
          </button>
        </div>

        <%!-- Eco Stats Table (Read-only) --%>
        <div class="p-0">
          <table class="table table-zebra w-full">
            <tbody>
              <tr>
                <td class="py-3 px-4 flex items-center gap-2">
                  <.icon name="hero-clock" class="w-4 h-4 text-info" />
                  <span class="text-sm">Elapsed Time</span>
                </td>
                <td class="py-3 px-4 text-right font-mono text-sm">{@elapsed_time}s</td>
              </tr>
              <tr>
                <td class="py-3 px-4 flex items-center gap-2">
                  <.icon name="hero-cube" class="w-4 h-4 text-mass" />
                  <span class="text-sm">Mass in Storage</span>
                </td>
                <td class="py-3 px-4 text-right font-mono text-sm text-mass">{@mass_in_storage}</td>
              </tr>
              <tr>
                <td class="py-3 px-4 flex items-center gap-2">
                  <.icon name="hero-bolt" class="w-4 h-4 text-energy" />
                  <span class="text-sm">Energy in Storage</span>
                </td>
                <td class="py-3 px-4 text-right font-mono text-sm text-energy">
                  {@energy_in_storage}
                </td>
              </tr>
              <tr>
                <td class="py-3 px-4 flex items-center gap-2">
                  <.icon name="hero-arrow-trending-up" class="w-4 h-4 text-mass" />
                  <span class="text-sm">Mass Income</span>
                </td>
                <td class="py-3 px-4 text-right font-mono text-sm text-mass">+{@mass_per_sec}/s</td>
              </tr>
              <tr>
                <td class="py-3 px-4 flex items-center gap-2">
                  <.icon name="hero-arrow-trending-down" class="w-4 h-4 text-energy" />
                  <span class="text-sm">Energy Income</span>
                </td>
                <td class="py-3 px-4 text-right font-mono text-sm text-energy">
                  +{@energy_per_sec}/s
                </td>
              </tr>
              <tr>
                <td class="py-3 px-4 flex items-center gap-2">
                  <.icon name="hero-wrench" class="w-4 h-4 text-build" />
                  <span class="text-sm">Build Power</span>
                </td>
                <td class="py-3 px-4 text-right font-mono text-sm">{@build_power} BP</td>
              </tr>
            </tbody>
          </table>
        </div>

        <%!-- Modal Footer --%>
        <div class="p-4 border-t border-base-300 bg-base-200/50">
          <div class="flex items-center justify-between">
            <span class="text-xs text-base-content/60">
              <.icon name="hero-lock-closed" class="w-3 h-3 inline" />
            </span>
            <button
              type="button"
              class="btn btn-sm btn-primary"
              phx-click="close_edge_info"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # ===== Event Handlers =====

  @impl true
  def handle_event("add_unit_node", _params, socket) do
    n = System.unique_integer([:positive])
    flow = socket.assigns.flow

    # Calculate position based on existing nodes
    unit_count = count_unit_nodes(flow)
    x_pos = 250 + unit_count * 180
    y_pos = 100 + rem(unit_count, 3) * 150

    node =
      Node.new(
        "unit-#{n}",
        %{x: x_pos, y: y_pos},
        %{
          unit: socket.assigns.default_unit,
          quantity: 1,
          finished_time: nil
        },
        type: :unit,
        handles: [Handle.target(:left), Handle.source(:right)]
      )

    flow = State.add_node(flow, node)
    {:noreply, assign(socket, flow: flow, simulation_run: false)}
  end

  @impl true
  def handle_event("run_simulation", _params, socket) do
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

    {:noreply, assign(socket, flow: flow, simulation_run: true)}
  end

  @impl true
  def handle_event("clear_simulation", _params, socket) do
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
    {:noreply, assign(socket, flow: flow, simulation_run: false)}
  end

  @impl true
  def handle_event("show_edge_info", %{"edge_id" => edge_id}, socket) do
    {:noreply,
     assign(socket,
       show_edge_info: true,
       selected_edge_id: edge_id
     )}
  end

  @impl true
  def handle_event("close_edge_info", _params, socket) do
    {:noreply,
     assign(socket,
       show_edge_info: false,
       selected_edge_id: nil
     )}
  end

  @impl true
  def handle_event("select_node", _params, socket) do
    # Node selection is handled by LiveFlow's lf:selection_change event
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_unit", _params, socket) do
    # Unit node click - just let LiveFlow handle the selection
    {:noreply, socket}
  end

  @impl true
  def handle_event("increase_quantity", %{"node-id" => node_id}, socket) do
    flow =
      update_node_data(socket.assigns.flow, node_id, fn data ->
        current_qty = data[:quantity] || 1
        unit = data[:unit]
        new_qty = current_qty + 1

        if unit do
          mass = unit.build_cost_mass * new_qty
          energy = unit.build_cost_energy * new_qty
          build_time = unit.build_time * new_qty

          require Logger

          Logger.info(
            "[#{node_id}] #{unit.unit_id}, qty=#{new_qty}, mass=#{trunc(mass)}, energy=#{trunc(energy)}, build_time=#{trunc(build_time)}"
          )
        end

        %{data | quantity: new_qty}
      end)

    {:noreply, assign(socket, flow: flow, simulation_run: false)}
  end

  @impl true
  def handle_event("decrease_quantity", %{"node-id" => node_id}, socket) do
    flow =
      update_node_data(socket.assigns.flow, node_id, fn data ->
        current_qty = data[:quantity] || 1
        # Don't go below 1
        new_qty = max(1, current_qty - 1)
        unit = data[:unit]

        if unit && new_qty != current_qty do
          mass = unit.build_cost_mass * new_qty
          energy = unit.build_cost_energy * new_qty
          build_time = unit.build_time * new_qty

          require Logger

          Logger.info(
            "[#{node_id}] #{unit.unit_id}, qty=#{new_qty}, mass=#{trunc(mass)}, energy=#{trunc(energy)}, build_time=#{trunc(build_time)}"
          )
        end

        %{data | quantity: new_qty}
      end)

    {:noreply, assign(socket, flow: flow, simulation_run: false)}
  end

  @impl true
  def handle_event("open_unit_selector", %{"node-id" => node_id}, socket) do
    # Get current unit for this node
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
        # Remove if already active
        List.delete(active_filters, filter_key)
      else
        # Add new filter, removing others from same group
        # Determine which group this filter belongs to
        group_filters =
          cond do
            filter_key in @usage_filters -> @usage_filters
            filter_key in @tech_filters -> @tech_filters
            true -> []
          end

        # Remove any filters from the same group, then add new one
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
  def handle_event("open_initial_settings", %{"node-id" => _node_id}, socket) do
    # Get current initial node values
    initial_node = socket.assigns.flow.nodes["initial"]
    data = initial_node && initial_node.data

    form =
      if data do
        %{
          "mass_in_storage" => data[:mass_in_storage] || 650,
          "energy_in_storage" => data[:energy_in_storage] || 5000,
          "mass_per_sec" => data[:mass_per_sec] || 1.0,
          "energy_per_sec" => data[:energy_per_sec] || 20.0,
          "build_power" => data[:build_power] || 10
        }
      else
        socket.assigns.initial_settings_form
      end

    {:noreply,
     assign(socket,
       show_initial_settings: true,
       initial_settings_form: form
     )}
  end

  @impl true
  def handle_event("close_initial_settings", _params, socket) do
    {:noreply, assign(socket, show_initial_settings: false)}
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
  def handle_event("save_initial_settings", params, socket) do
    require Logger

    Logger.info(
      "[initial] mass_storage=#{params["mass_in_storage"]}, energy_storage=#{params["energy_in_storage"]}, mass_per_sec=#{params["mass_per_sec"]}, energy_per_sec=#{params["energy_per_sec"]}, build_power=#{params["build_power"]}"
    )

    flow =
      update_node_data(socket.assigns.flow, "initial", fn data ->
        %{
          data
          | mass_in_storage: parse_int(params["mass_in_storage"]),
            energy_in_storage: parse_int(params["energy_in_storage"]),
            mass_per_sec: parse_float(params["mass_per_sec"]),
            energy_per_sec: parse_float(params["energy_per_sec"]),
            build_power: parse_int(params["build_power"])
        }
      end)

    {:noreply,
     assign(socket,
       flow: flow,
       show_initial_settings: false,
       simulation_run: false
     )}
  end

  @impl true
  def handle_event("search_units", %{"value" => search}, socket) do
    {:noreply, assign(socket, unit_search: search)}
  end

  @impl true
  def handle_event("select_unit_for_node", %{"unit_id" => unit_id}, socket) do
    node_id = socket.assigns.selected_node_id
    unit = Enum.find(socket.assigns.units, &(&1.unit_id == unit_id))
    qty = 1
    mass = unit.build_cost_mass * qty
    energy = unit.build_cost_energy * qty
    build_time = unit.build_time * qty

    require Logger

    Logger.info(
      "[#{node_id}] #{unit.unit_id}, qty=#{qty}, mass=#{trunc(mass)}, energy=#{trunc(energy)}, build_time=#{trunc(build_time)}"
    )

    flow =
      update_node_data(socket.assigns.flow, node_id, fn data ->
        %{data | unit: unit, finished_time: nil, quantity: qty}
      end)

    {:noreply,
     assign(socket,
       flow: flow,
       show_unit_selector: false,
       selected_node_id: nil,
       unit_search: "",
       simulation_run: false
     )}
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
    # Prevent deletion of initial node
    flow = ensure_initial_node(flow, socket.assigns.default_unit)
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

  @impl true
  def handle_info({:lf_node_click, node_id}, socket) do
    require Logger
    Logger.debug("[EcoWorkflow] Node clicked: #{node_id}")
    {:noreply, socket}
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

  # ===== Private Helpers =====

  defp parse_int(value) when is_binary(value), do: String.to_integer(value)
  defp parse_int(value) when is_integer(value), do: value
  defp parse_int(_), do: 0

  defp parse_float(value) when is_binary(value) do
    case Float.parse(value) do
      {f, _} -> f
      :error -> 0.0
    end
  end

  defp parse_float(value) when is_float(value), do: value
  defp parse_float(value) when is_integer(value), do: value * 1.0
  defp parse_float(_), do: 0.0

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

  # Build JSON map of edge IDs to tooltip data for JS hook
  # Returns structured data with mass and energy as separate fields
  defp build_edge_tooltips(edges, true = _simulation_run) do
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

  defp build_edge_tooltips(_edges, false = _simulation_run), do: "{}"

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
    # Position nodes in a horizontal line with vertical staggering
    node_specs = [
      {"unit-t3-eng-1", units.t3_engineer, %{x: 250, y: 100}, 1},
      {"unit-t3-eng-2", units.t3_engineer, %{x: 400, y: 200}, 1},
      {"unit-t3-eng-3", units.t3_engineer, %{x: 550, y: 300}, 1},
      {"unit-t3-pgen", units.t3_pgen, %{x: 700, y: 200}, 1},
      {"unit-t3-mex", units.t3_mex, %{x: 850, y: 200}, 1},
      {"unit-fatboy", units.fatboy, %{x: 1000, y: 200}, 1}
    ]

    # Create unit nodes
    {unit_nodes, _} =
      Enum.map_reduce(node_specs, [], fn {id, unit, pos, qty}, acc ->
        node =
          Node.new(
            id,
            pos,
            %{
              unit: unit,
              quantity: qty,
              finished_time: nil
            },
            type: :unit,
            handles: [Handle.target(:left), Handle.source(:right)]
          )

        {node, [node | acc]}
      end)

    # Create edges connecting the chain
    # initial -> eng-1 -> eng-2 -> eng-3 -> pgen -> mex -> fatboy
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

  defp ensure_initial_node(flow, _default_unit) do
    if Map.has_key?(flow.nodes, "initial") do
      flow
    else
      # Recreate initial node if it was deleted
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

  defp count_unit_nodes(flow) do
    flow.nodes
    |> Map.values()
    |> Enum.count(&(&1.type == :unit))
  end

  defp update_node_data(flow, node_id, update_fn) do
    case Map.get(flow.nodes, node_id) do
      nil ->
        flow

      node ->
        updated_node = %{node | data: update_fn.(node.data)}
        %{flow | nodes: Map.put(flow.nodes, node_id, updated_node)}
    end
  end

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
    # Prevent removal of initial node
    if id == "initial" do
      flow
    else
      State.remove_node(flow, id)
    end
  end

  defp apply_node_change(flow, _change), do: flow
end
