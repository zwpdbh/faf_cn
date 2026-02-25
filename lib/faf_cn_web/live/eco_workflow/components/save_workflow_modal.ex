defmodule FafCnWeb.EcoWorkflow.Components.SaveWorkflowModal do
  @moduledoc """
  LiveComponent for saving a new workflow.
  Handles form state and validation internally.
  """
  use FafCnWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="save-workflow-modal-backdrop"
      class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
      phx-click-away="close"
      phx-target={@myself}
    >
      <div class="bg-base-100 rounded-xl shadow-2xl w-full max-w-md overflow-hidden">
        <%!-- Modal Header --%>
        <div class="p-4 border-b border-base-300 flex items-center justify-between bg-linear-to-r from-info/10 to-transparent">
          <div class="flex items-center gap-2">
            <.icon name="hero-arrow-down-tray" class="w-5 h-5 text-info" />
            <h2 class="text-lg font-semibold">Save Workflow</h2>
          </div>
          <button class="btn btn-sm btn-ghost" phx-click="close" phx-target={@myself}>
            <.icon name="hero-x-mark" class="w-5 h-5" />
          </button>
        </div>

        <%!-- Modal Body --%>
        <div class="p-6">
          <.form
            for={@form}
            phx-submit="save"
            phx-target={@myself}
            class="space-y-4"
          >
            <div>
              <label class="label">
                <span class="label-text">Workflow Name</span>
              </label>
              <input
                type="text"
                name="name"
                value={@form[:name]}
                placeholder="Enter workflow name..."
                class="input input-bordered w-full"
                required
              />
            </div>

            <%= if @error do %>
              <div class="alert alert-error text-sm">
                <.icon name="hero-exclamation-triangle" class="w-4 h-4" />
                {@error}
              </div>
            <% end %>

            <div class="flex justify-end gap-2 pt-2">
              <button type="button" class="btn btn-ghost" phx-click="close" phx-target={@myself}>
                Cancel
              </button>
              <button type="submit" class="btn btn-primary">
                <.icon name="hero-document-check" class="w-4 h-4 mr-1" /> Save
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
    {:ok, assign(socket, form: %{name: ""}, error: nil)}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(error: nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("close", _params, socket) do
    # Notify parent to close modal
    send(self(), {:close_modal, :save_workflow})
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"name" => name}, socket) do
    if String.trim(name) == "" do
      {:noreply, assign(socket, error: "Name is required")}
    else
      # Notify parent to save
      send(self(), {:save_workflow, name})
      {:noreply, socket}
    end
  end
end
