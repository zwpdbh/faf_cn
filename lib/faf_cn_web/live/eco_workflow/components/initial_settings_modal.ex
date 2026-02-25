defmodule FafCnWeb.EcoWorkflow.Components.InitialSettingsModal do
  @moduledoc """
  LiveComponent for editing initial eco settings.
  """
  use FafCnWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="initial-settings-modal-backdrop"
      class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
      phx-click-away="close"
      phx-target={@myself}
    >
      <.form
        for={@form}
        phx-submit="save"
        phx-target={@myself}
        class="bg-base-100 rounded-xl shadow-2xl w-full max-w-md"
      >
        <%!-- Modal Header --%>
        <div class="p-4 border-b border-base-300 flex items-center justify-between">
          <h2 class="text-lg font-semibold">Initial Eco Settings</h2>
          <button
            class="btn btn-sm btn-ghost"
            phx-click="close"
            phx-target={@myself}
          >
            <.icon name="hero-x-mark" class="w-5 h-5" />
          </button>
        </div>

        <%!-- Settings Form --%>
        <div class="p-6 space-y-4">
          <%!-- Storage Section --%>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="label">
                <span class="label-text flex items-center gap-1">
                  <.icon name="hero-cube" class="w-4 h-4 text-mass" /> Mass Storage
                </span>
              </label>
              <input
                type="number"
                name="mass_in_storage"
                value={@form[:mass_in_storage]}
                class="input input-bordered w-full"
                min="0"
              />
            </div>
            <div>
              <label class="label">
                <span class="label-text flex items-center gap-1">
                  <.icon name="hero-bolt" class="w-4 h-4 text-energy" /> Energy Storage
                </span>
              </label>
              <input
                type="number"
                name="energy_in_storage"
                value={@form[:energy_in_storage]}
                class="input input-bordered w-full"
                min="0"
              />
            </div>
          </div>

          <%!-- Income Section --%>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="label">
                <span class="label-text flex items-center gap-1">
                  <.icon name="hero-arrow-trending-up" class="w-4 h-4 text-mass" /> Mass/sec
                </span>
              </label>
              <input
                type="number"
                name="mass_per_sec"
                value={@form[:mass_per_sec]}
                class="input input-bordered w-full"
                min="0"
                step="0.1"
              />
            </div>
            <div>
              <label class="label">
                <span class="label-text flex items-center gap-1">
                  <.icon name="hero-arrow-trending-down" class="w-4 h-4 text-energy" /> Energy/sec
                </span>
              </label>
              <input
                type="number"
                name="energy_per_sec"
                value={@form[:energy_per_sec]}
                class="input input-bordered w-full"
                min="0"
                step="0.1"
              />
            </div>
          </div>

          <%!-- Build Power --%>
          <div>
            <label class="label">
              <span class="label-text flex items-center gap-1">
                <.icon name="hero-wrench" class="w-4 h-4 text-build" /> Build Power
              </span>
            </label>
            <input
              type="number"
              name="build_power"
              value={@form[:build_power]}
              class="input input-bordered w-full"
              min="0"
            />
          </div>
        </div>

        <%!-- Modal Footer --%>
        <div class="p-4 border-t border-base-300 flex justify-end gap-2">
          <button
            type="button"
            class="btn btn-ghost"
            phx-click="close"
            phx-target={@myself}
          >
            Cancel
          </button>
          <button
            type="submit"
            class="btn btn-primary"
          >
            Save Changes
          </button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, assign(socket, form: default_form())}
  end

  @impl true
  def update(assigns, socket) do
    form = assigns.initial_data || default_form()
    {:ok, assign(socket, assigns |> Map.put(:form, form))}
  end

  @impl true
  def handle_event("close", _params, socket) do
    send(self(), {:close_modal, :initial_settings})
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", params, socket) do
    send(self(), {:save_initial_settings, params})
    {:noreply, socket}
  end

  defp default_form do
    %{
      mass_in_storage: 650,
      energy_in_storage: 5000,
      mass_per_sec: 1.0,
      energy_per_sec: 20.0,
      build_power: 10
    }
  end
end
