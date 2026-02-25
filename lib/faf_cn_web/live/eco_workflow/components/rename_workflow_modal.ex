defmodule FafCnWeb.EcoWorkflow.Components.RenameWorkflowModal do
  @moduledoc """
  LiveComponent for renaming a workflow.
  """
  use FafCnWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="rename-workflow-modal-backdrop"
      class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
      phx-click-away="close"
      phx-target={@myself}
    >
      <div class="bg-base-100 rounded-xl shadow-2xl w-full max-w-md overflow-hidden">
        <%!-- Modal Header --%>
        <div class="p-4 border-b border-base-300 flex items-center justify-between bg-linear-to-r from-info/10 to-transparent">
          <div class="flex items-center gap-2">
            <.icon name="hero-pencil" class="w-5 h-5 text-info" />
            <h2 class="text-lg font-semibold">Rename Workflow</h2>
          </div>
          <button class="btn btn-sm btn-ghost" phx-click="close" phx-target={@myself}>
            <.icon name="hero-x-mark" class="w-5 h-5" />
          </button>
        </div>

        <%!-- Modal Body --%>
        <div class="p-6">
          <.form
            for={@form}
            phx-submit="rename"
            phx-target={@myself}
            class="space-y-4"
          >
            <div>
              <label class="label">
                <span class="label-text">New Name</span>
              </label>
              <input
                type="text"
                name="name"
                value={@form[:name]}
                placeholder="Enter new name..."
                class="input input-bordered w-full"
                required
              />
            </div>

            <div class="flex justify-end gap-2 pt-2">
              <button type="button" class="btn btn-ghost" phx-click="close" phx-target={@myself}>
                Cancel
              </button>
              <button type="submit" class="btn btn-primary">
                Rename
              </button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, assign(socket, form: %{name: ""})}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(form: %{name: assigns.current_name || ""})

    {:ok, socket}
  end

  @impl true
  def handle_event("close", _params, socket) do
    send(self(), {:close_modal, :rename_workflow})
    {:noreply, socket}
  end

  @impl true
  def handle_event("rename", %{"name" => name}, socket) do
    send(self(), {:rename_workflow, name})
    {:noreply, socket}
  end
end
