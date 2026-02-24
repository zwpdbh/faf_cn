defmodule FafCnWeb.EcoWorkflow.MassStorageNode do
  @moduledoc """
  Mass Storage Node - Tracks mass storage capacity and current amount.
  """
  use Phoenix.LiveComponent
  import FafCnWeb.CoreComponents

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    value = Map.get(assigns.node.data, :value, 0)
    max = Map.get(assigns.node.data, :max, 100)
    percentage = if max > 0, do: min(100, max(0, value / max * 100)), else: 0

    assigns =
      assigns
      |> assign(:value, value)
      |> assign(:max, max)
      |> assign(:percentage, percentage)

    ~H"""
    <div class="workflow-node">
      <div class="workflow-node-header workflow-node-mass">
        <.icon name="hero-cube" class="w-4 h-4" />
        <span>{@node.data[:label] || "Mass Storage"}</span>
      </div>
      <div class="workflow-node-body">
        <div class="workflow-node-value text-mass">
          {@value} / {@max}
        </div>
        <div class="workflow-node-progress">
          <div class="workflow-node-progress-bar bg-mass" style="width: {@percentage}%"></div>
        </div>
        <div class="workflow-node-unit">{@node.data[:unit]}</div>
      </div>
    </div>
    """
  end
end
