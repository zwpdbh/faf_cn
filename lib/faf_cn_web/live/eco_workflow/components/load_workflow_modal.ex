defmodule FafCnWeb.EcoWorkflow.Components.LoadWorkflowModal do
  @moduledoc """
  LiveComponent for loading a saved workflow.
  """
  use FafCnWeb, :live_component

  attr :workflows, :list, required: true
  attr :current_workflow_id, :any, required: true
  attr :current_user, :any, required: true

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="load-workflow-modal-backdrop"
      class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
      phx-click-away="close"
      phx-target={@myself}
    >
      <div class="bg-base-100 rounded-xl shadow-2xl w-full max-w-md overflow-hidden">
        <%!-- Modal Header --%>
        <div class="p-4 border-b border-base-300 flex items-center justify-between bg-linear-to-r from-info/10 to-transparent">
          <div class="flex items-center gap-2">
            <.icon name="hero-folder-open" class="w-5 h-5 text-info" />
            <h2 class="text-lg font-semibold">Load Workflow</h2>
          </div>
          <button class="btn btn-sm btn-ghost" phx-click="close" phx-target={@myself}>
            <.icon name="hero-x-mark" class="w-5 h-5" />
          </button>
        </div>

        <%!-- Modal Body --%>
        <div class="p-4 max-h-[400px] overflow-y-auto">
          <%= if @workflows == [] do %>
            <div class="text-center py-8 text-base-content/60">
              <.icon name="hero-folder" class="w-12 h-12 mx-auto mb-2 opacity-50" />
              <p>No saved workflows yet</p>
            </div>
          <% else %>
            <div class="space-y-2">
              <%= for workflow <- @workflows do %>
                <div class={[
                  "flex items-center justify-between p-3 rounded-lg border",
                  @current_workflow_id == workflow.id &&
                    "bg-info/10 border-info/30",
                  @current_workflow_id != workflow.id &&
                    "bg-base-200 border-base-300 hover:bg-base-300"
                ]}>
                  <button
                    class="flex-1 text-left"
                    phx-click="load"
                    phx-value-workflow_id={workflow.id}
                    phx-target={@myself}
                  >
                    <div class="font-medium">{workflow.name}</div>
                    <div class="text-xs text-base-content/60">
                      {Calendar.strftime(workflow.inserted_at, "%Y-%m-%d %H:%M")}
                    </div>
                  </button>
                  <%= if @current_workflow_id == workflow.id do %>
                    <span class="badge badge-info badge-sm">Current</span>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>

        <%!-- Modal Footer --%>
        <div class="p-4 border-t border-base-300 bg-base-200/50">
          <button
            type="button"
            class="btn btn-sm btn-primary w-full"
            phx-click="close"
            phx-target={@myself}
          >
            Close
          </button>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    workflows = if assigns.current_user, do: assigns.workflows, else: []
    {:ok, assign(socket, assigns |> Map.put(:workflows, workflows))}
  end

  @impl true
  def handle_event("close", _params, socket) do
    send(self(), {:close_modal, :load_workflow})
    {:noreply, socket}
  end

  @impl true
  def handle_event("load", %{"workflow_id" => workflow_id}, socket) do
    send(self(), {:load_workflow, workflow_id})
    {:noreply, socket}
  end
end
