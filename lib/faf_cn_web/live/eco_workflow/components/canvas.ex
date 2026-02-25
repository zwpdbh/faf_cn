defmodule FafCnWeb.EcoWorkflow.Components.Canvas do
  @moduledoc """
  Canvas component wrapping the LiveFlow visualization.
  """
  use FafCnWeb, :html

  alias LiveFlow.State

  attr :flow, State, required: true
  attr :simulation_run, :boolean, required: true
  attr :node_types, :map, required: true
  attr :edge_types, :map, required: true
  attr :edge_tooltips, :string, required: true

  def canvas(assigns) do
    ~H"""
    <div
      class="flex-1 relative"
      id="eco-workflow-container"
      data-simulation-run={to_string(@simulation_run)}
      data-edge-tooltips={@edge_tooltips}
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
    """
  end
end
