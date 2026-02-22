defmodule FafCnWeb.EcoWorkflow.FetchNode do
  @moduledoc """
  Fetch Node - Fetches financial data from external sources.
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
      <div class="workflow-node-header workflow-node-fetch">
        <.icon name="hero-cloud-arrow-down" class="w-4 h-4" />
        <span>{@node.data[:label] || "Fetch"}</span>
      </div>
      <div class="workflow-node-body">
        <div class="workflow-node-field">
          <span class="workflow-node-label">Source:</span>
          <span class="workflow-node-value">{@node.data[:source]}</span>
        </div>
        <div class="workflow-node-field">
          <span class="workflow-node-label">Symbol:</span>
          <span class="workflow-node-value font-mono">{@node.data[:symbol]}</span>
        </div>
      </div>
    </div>
    """
  end
end
