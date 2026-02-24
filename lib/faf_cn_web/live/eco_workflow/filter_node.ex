defmodule FafCnWeb.EcoWorkflow.FilterNode do
  @moduledoc """
  Filter Node - Filters data based on conditions.
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
      <div class="workflow-node-header workflow-node-filter">
        <.icon name="hero-funnel" class="w-4 h-4" />
        <span>{@node.data[:label] || "Filter"}</span>
      </div>
      <div class="workflow-node-body">
        <div class="workflow-node-field">
          <span class="workflow-node-label">Condition:</span>
        </div>
        <div class="workflow-node-code">
          {@node.data[:condition]}
        </div>
      </div>
    </div>
    """
  end
end
