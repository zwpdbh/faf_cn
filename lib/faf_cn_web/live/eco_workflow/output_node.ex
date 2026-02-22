defmodule FafCnWeb.EcoWorkflow.OutputNode do
  @moduledoc """
  Output Node - Generates final output/report.
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
      <div class="workflow-node-header workflow-node-output">
        <.icon name="hero-document-text" class="w-4 h-4" />
        <span>{@node.data[:label] || "Output"}</span>
      </div>
      <div class="workflow-node-body">
        <div class="workflow-node-field">
          <span class="workflow-node-label">Format:</span>
          <span class="workflow-node-value">{@node.data[:format]}</span>
        </div>
      </div>
    </div>
    """
  end
end
