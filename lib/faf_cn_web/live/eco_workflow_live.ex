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
  on_mount {FafCnWeb.UserAuth, :mount_current_user}

  @default_engineer_id "UEL0105"

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

    flow = create_initial_flow(default_unit)

    {:ok,
     assign(socket,
       page_title: "Eco Workflow",
       flow: flow,
       units: units,
       units_by_faction: units_by_faction,
       default_unit: default_unit,
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
      |> assign(:mass_in_storage, edge_data[:mass_in_storage] || 650)
      |> assign(:energy_in_storage, edge_data[:energy_in_storage] || 5000)
      |> assign(:mass_per_sec, edge_data[:mass_per_sec] || 1.0)
      |> assign(:energy_per_sec, edge_data[:energy_per_sec] || 20.0)
      |> assign(:build_power, edge_data[:build_power] || 10)
      |> assign(:elapsed_time, edge_data[:elapsed_time] || 0)

    ~H"""
    <div
      id="edge-info-modal-backdrop"
      class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
      phx-click-away="close_edge_info"
    >
      <div class="bg-base-100 rounded-xl shadow-2xl w-full max-w-md overflow-hidden">
        <%!-- Modal Header --%>
        <div class="p-4 border-b border-base-300 flex items-center justify-between bg-gradient-to-r from-info/10 to-transparent">
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
            <thead>
              <tr class="bg-base-200">
                <th class="text-left py-3 px-4 text-sm font-medium text-base-content/70">Metric</th>
                <th class="text-right py-3 px-4 text-sm font-medium text-base-content/70">Value</th>
              </tr>
            </thead>
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
              <.icon name="hero-lock-closed" class="w-3 h-3 inline" /> Read-only during simulation
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
    # Generate dummy simulation results
    flow = socket.assigns.flow

    # Update nodes with finished times and read-only flag
    updated_nodes =
      Enum.reduce(flow.nodes, %{}, fn {id, node}, acc ->
        updated_node =
          if node.type == :unit do
            # Generate dummy finished time based on position
            base_time = 30
            random_offset = :rand.uniform(60)
            finished_time = base_time + random_offset

            %{node | data: Map.put(node.data, :finished_time, finished_time), deletable: false}
          else
            # Initial node - also mark as non-deletable during simulation
            %{node | deletable: false}
          end

        Map.put(acc, id, updated_node)
      end)

    # Update edges with dummy eco status and read-only flag
    updated_edges =
      Enum.reduce(flow.edges, %{}, fn {id, edge}, acc ->
        elapsed_time = :rand.uniform(120)
        mass_per_sec = 1.0 + elapsed_time * 0.05
        energy_per_sec = 20.0 + elapsed_time * 0.2

        edge_data = %{
          mass_in_storage: 650 + trunc(elapsed_time * 0.5),
          energy_in_storage: max(0, 5000 - trunc(elapsed_time * 10)),
          mass_per_sec: mass_per_sec,
          energy_per_sec: energy_per_sec,
          build_power: 10 + trunc(elapsed_time * 0.1),
          elapsed_time: elapsed_time,
          simulation_run: true,
          # Store formatted tooltip text for CSS display
          tooltip_text:
            "Mass: -#{format_tooltip_value(mass_per_sec)}/s  |  Energy: -#{format_tooltip_value(energy_per_sec)}/s"
        }

        # No label - hover shows tooltip with mass/energy drain
        # Double-click opens modal with full details
        Map.put(acc, id, %{edge | data: edge_data, deletable: false, label: nil})
      end)

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
      cond do
        # Remove if already active
        filter_key in active_filters ->
          List.delete(active_filters, filter_key)

        # Add new filter, removing others from same group
        true ->
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
    flow = create_initial_flow(socket.assigns.default_unit)
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
      "#{trunc(value)}"
    else
      "#{Float.round(value, 1)}"
    end
  end

  defp format_tooltip_value(value) when is_integer(value), do: "#{value}"
  defp format_tooltip_value(_), do: "0"

  # Build JSON map of edge IDs to tooltip text for JS hook
  defp build_edge_tooltips(edges, true = _simulation_run) do
    tooltips =
      Enum.reduce(edges, %{}, fn {id, edge}, acc ->
        data = edge.data || %{}

        if data[:simulation_run] do
          mass = data[:mass_per_sec] || 0
          energy = data[:energy_per_sec] || 0

          text =
            "Mass: -#{format_tooltip_value(mass)}/s  |  Energy: -#{format_tooltip_value(energy)}/s"

          Map.put(acc, id, text)
        else
          acc
        end
      end)

    Jason.encode!(tooltips)
  end

  defp build_edge_tooltips(_edges, false = _simulation_run), do: "{}"

  defp create_initial_flow(default_unit) do
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

    # Add one default unit node connected to initial
    unit_node =
      Node.new(
        "unit-default",
        %{x: 280, y: 150},
        %{
          unit: default_unit,
          quantity: 1,
          finished_time: nil
        },
        type: :unit,
        handles: [Handle.target(:left), Handle.source(:right)]
      )

    edge =
      Edge.new("e-initial", "initial", "unit-default",
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

    State.new(nodes: [initial_node, unit_node], edges: [edge])
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
