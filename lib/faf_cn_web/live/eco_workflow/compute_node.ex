defmodule FafCnWeb.EcoWorkflow.ComputeNode do
  @moduledoc """
  Compute Node - Performs calculations on data.
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
      <div class="workflow-node-header workflow-node-compute">
        <.icon name="hero-calculator" class="w-4 h-4" />
        <span>{@node.data[:label] || "Compute"}</span>
      </div>
      <div class="workflow-node-body">
        <div class="workflow-node-field">
          <span class="workflow-node-label">Operation:</span>
        </div>
        <div class="workflow-node-value">
          {@node.data[:operation]}
        </div>
      </div>
    </div>
    """
  end
end
