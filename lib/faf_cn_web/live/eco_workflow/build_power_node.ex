defmodule FafCnWeb.EcoWorkflow.BuildPowerNode do
  @moduledoc """
  Build Power Node - Represents build power (BP) for construction.
  """
  use Phoenix.LiveComponent
  import FafCnWeb.CoreComponents

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="workflow-node">
      <div class="workflow-node-header workflow-node-build">
        <.icon name="hero-wrench" class="w-4 h-4" />
        <span>{@node.data[:label] || "Build Power"}</span>
      </div>
      <div class="workflow-node-body">
        <div class="workflow-node-value text-build text-center">
          {@node.data[:value] || 0}
        </div>
        <div class="workflow-node-unit text-center">{@node.data[:unit]}</div>
        <div class="mt-2 text-xs text-center text-base-content/60">
          Build Rate
        </div>
      </div>
    </div>
    """
  end
end
