defmodule FafCnWeb.EcoWorkflow.Handlers.NodeOperations do
  @moduledoc """
  Handles node operations: add, remove, update nodes.
  """

  import Phoenix.Component

  alias LiveFlow.{State, Node, Handle}

  @doc """
  Add a new unit node to the flow.
  """
  def add_unit_node(socket, default_unit) do
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
          unit: default_unit,
          quantity: 1,
          finished_time: nil
        },
        type: :unit,
        handles: [Handle.target(:left), Handle.source(:right)]
      )

    flow = State.add_node(flow, node)

    socket
    |> assign(flow: flow, simulation_run: false)
    |> mark_workflow_dirty()
    |> maybe_trigger_auto_save()
  end

  @doc """
  Increase quantity for a unit node.
  """
  def increase_quantity(socket, node_id) do
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

    socket
    |> assign(flow: flow, simulation_run: false)
    |> mark_workflow_dirty()
    |> maybe_trigger_auto_save()
  end

  @doc """
  Decrease quantity for a unit node.
  """
  def decrease_quantity(socket, node_id) do
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

    socket
    |> assign(flow: flow, simulation_run: false)
    |> mark_workflow_dirty()
    |> maybe_trigger_auto_save()
  end

  @doc """
  Select a unit for a node.
  """
  def select_unit_for_node(socket, node_id, unit_id, units) do
    unit = Enum.find(units, &(&1.unit_id == unit_id))
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

    socket
    |> assign(
      flow: flow,
      show_unit_selector: false,
      selected_node_id: nil,
      unit_search: "",
      simulation_run: false
    )
    |> mark_workflow_dirty()
    |> maybe_trigger_auto_save()
  end

  @doc """
  Update initial node settings.
  """
  def save_initial_settings(socket, params) do
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

    assign(socket,
      flow: flow,
      show_initial_settings: false,
      simulation_run: false
    )
  end

  @doc """
  Get initial node settings form data.
  """
  def get_initial_settings_form(flow) do
    initial_node = flow.nodes["initial"]
    data = initial_node && initial_node.data

    if data do
      %{
        "mass_in_storage" => data[:mass_in_storage] || 650,
        "energy_in_storage" => data[:energy_in_storage] || 5000,
        "mass_per_sec" => data[:mass_per_sec] || 1.0,
        "energy_per_sec" => data[:energy_per_sec] || 20.0,
        "build_power" => data[:build_power] || 10
      }
    else
      %{
        "mass_in_storage" => 650,
        "energy_in_storage" => 5000,
        "mass_per_sec" => 1.0,
        "energy_per_sec" => 20.0,
        "build_power" => 10
      }
    end
  end

  # ===== LiveFlow Node Change Handlers =====

  @doc """
  Apply node changes from LiveFlow.
  """
  def apply_node_changes(socket, changes) do
    flow =
      Enum.reduce(changes, socket.assigns.flow, fn change, acc ->
        apply_node_change(acc, change)
      end)

    socket
    |> assign(flow: flow)
    |> mark_workflow_dirty()
    |> maybe_trigger_auto_save()
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

  # ===== Private Helpers =====

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
end
