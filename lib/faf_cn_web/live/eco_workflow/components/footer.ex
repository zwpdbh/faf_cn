defmodule FafCnWeb.EcoWorkflow.Components.Footer do
  @moduledoc """
  Footer component showing workflow statistics and help text.
  """
  use FafCnWeb, :html

  alias LiveFlow.State

  attr :flow, State, required: true

  def footer(assigns) do
    ~H"""
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
    """
  end

  defp count_unit_nodes(flow) do
    flow.nodes
    |> Map.values()
    |> Enum.count(&(&1.type == :unit))
  end
end
