defmodule FafCnWeb.EcoWorkflow.InitialNode do
  @moduledoc """
  Initial Node - Compact rectangular representation of starting economy status.

  Displays key eco stats in a concise format.
  Double-click to open settings modal.
  """
  use Phoenix.LiveComponent
  import FafCnWeb.CoreComponents

  @impl true
  def update(assigns, socket) do
    data = assigns.node.data

    socket =
      socket
      |> assign(:node, assigns.node)
      |> assign(:id, assigns.id)
      |> assign(:mass_in_storage, data[:mass_in_storage] || 650)
      |> assign(:energy_in_storage, data[:energy_in_storage] || 5000)
      |> assign(:mass_per_sec, data[:mass_per_sec] || 1.0)
      |> assign(:energy_per_sec, data[:energy_per_sec] || 20.0)
      |> assign(:build_power, data[:build_power] || 10)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="workflow-node-initial-compact" phx-hook="WorkflowNode" id="workflow-node-initial">
      <%!-- Header --%>
      <div class="workflow-node-initial-compact-header">
        <.icon name="hero-play-circle" class="w-3 h-3" />
        <span class="text-[10px] font-semibold uppercase tracking-wide">Start</span>
        <%!-- Edit Button --%>
        <button
          type="button"
          class="workflow-node-initial-edit-btn"
          id="initial-edit-btn"
          phx-hook="EditButton"
          data-event="open_initial_settings"
          data-node-id="initial"
          title="Edit initial settings"
        >
          <.icon name="hero-pencil-square" class="w-3 h-3" />
        </button>
      </div>

      <%!-- Compact Stats Grid --%>
      <div class="workflow-node-initial-compact-body">
        <%!-- Row 1: Storage --%>
        <div class="flex items-center justify-between gap-3">
          <div class="flex items-center gap-1" title="Mass Storage">
            <.icon name="hero-cube" class="w-3 h-3 text-mass" />
            <span class="text-[10px] font-medium">{@mass_in_storage}</span>
          </div>
          <div class="flex items-center gap-1" title="Energy Storage">
            <.icon name="hero-bolt" class="w-3 h-3 text-energy" />
            <span class="text-[10px] font-medium">{@energy_in_storage}</span>
          </div>
        </div>

        <%!-- Row 2: Income --%>
        <div class="flex items-center justify-between gap-3">
          <div class="flex items-center gap-1" title="Mass Income">
            <span class="text-[9px] text-mass">+{@mass_per_sec}/s</span>
          </div>
          <div class="flex items-center gap-1" title="Energy Income">
            <span class="text-[9px] text-energy">+{@energy_per_sec}/s</span>
          </div>
        </div>

        <%!-- Row 3: Build Power --%>
        <div class="flex items-center justify-center gap-1 pt-0.5 border-t border-base-300/50 mt-0.5">
          <.icon name="hero-wrench" class="w-3 h-3 text-build" />
          <span class="text-[10px] font-medium">{@build_power} BP</span>
        </div>
      </div>
    </div>
    """
  end
end
