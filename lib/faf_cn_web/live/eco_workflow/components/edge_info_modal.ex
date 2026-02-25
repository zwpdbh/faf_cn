defmodule FafCnWeb.EcoWorkflow.Components.EdgeInfoModal do
  @moduledoc """
  LiveComponent for displaying edge eco statistics (read-only).
  """
  use FafCnWeb, :live_component

  alias FafCnWeb.EcoWorkflow.Handlers.Simulation

  @impl true
  def render(assigns) do
    edge_data = assigns.edge && assigns.edge.data
    formatted = Simulation.format_edge_data(edge_data || %{})

    assigns =
      assigns
      |> assign(:mass_in_storage, formatted.mass_in_storage)
      |> assign(:energy_in_storage, formatted.energy_in_storage)
      |> assign(:mass_per_sec, formatted.mass_per_sec)
      |> assign(:energy_per_sec, formatted.energy_per_sec)
      |> assign(:build_power, formatted.build_power)
      |> assign(:elapsed_time, formatted.elapsed_time)

    ~H"""
    <div
      id="edge-info-modal-backdrop"
      class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
      phx-click-away="close"
      phx-target={@myself}
    >
      <div class="bg-base-100 rounded-xl shadow-2xl w-full max-w-md overflow-hidden">
        <%!-- Modal Header --%>
        <div class="p-4 border-b border-base-300 flex items-center justify-between bg-linear-to-r from-info/10 to-transparent">
          <div class="flex items-center gap-2">
            <.icon name="hero-information-circle" class="w-5 h-5 text-info" />
            <h2 class="text-lg font-semibold">Eco Statistics</h2>
          </div>
          <button
            class="btn btn-sm btn-ghost"
            phx-click="close"
            phx-target={@myself}
          >
            <.icon name="hero-x-mark" class="w-5 h-5" />
          </button>
        </div>

        <%!-- Eco Stats Table (Read-only) --%>
        <div class="p-0">
          <table class="table table-zebra w-full">
            <tbody>
              <tr>
                <td class="py-3 px-4 flex items-center gap-2">
                  <.icon name="hero-clock" class="w-4 h-4 text-info" />
                  <span class="text-sm">Elapsed Time</span>
                </td>
                <td class="py-3 px-4 text-right font-mono text-sm">{@elapsed_time}s</td>
              </tr>
              <tr>
                <td class="py-3 px-4 flex items-center gap-2">
                  <.icon name="hero-cube" class="w-4 h-4 text-mass" />
                  <span class="text-sm">Mass in Storage</span>
                </td>
                <td class="py-3 px-4 text-right font-mono text-sm text-mass">{@mass_in_storage}</td>
              </tr>
              <tr>
                <td class="py-3 px-4 flex items-center gap-2">
                  <.icon name="hero-bolt" class="w-4 h-4 text-energy" />
                  <span class="text-sm">Energy in Storage</span>
                </td>
                <td class="py-3 px-4 text-right font-mono text-sm text-energy">
                  {@energy_in_storage}
                </td>
              </tr>
              <tr>
                <td class="py-3 px-4 flex items-center gap-2">
                  <.icon name="hero-arrow-trending-up" class="w-4 h-4 text-mass" />
                  <span class="text-sm">Mass Income</span>
                </td>
                <td class="py-3 px-4 text-right font-mono text-sm text-mass">+{@mass_per_sec}/s</td>
              </tr>
              <tr>
                <td class="py-3 px-4 flex items-center gap-2">
                  <.icon name="hero-arrow-trending-down" class="w-4 h-4 text-energy" />
                  <span class="text-sm">Energy Income</span>
                </td>
                <td class="py-3 px-4 text-right font-mono text-sm text-energy">
                  +{@energy_per_sec}/s
                </td>
              </tr>
              <tr>
                <td class="py-3 px-4 flex items-center gap-2">
                  <.icon name="hero-wrench" class="w-4 h-4 text-build" />
                  <span class="text-sm">Build Power</span>
                </td>
                <td class="py-3 px-4 text-right font-mono text-sm">{@build_power} BP</td>
              </tr>
            </tbody>
          </table>
        </div>

        <%!-- Modal Footer --%>
        <div class="p-4 border-t border-base-300 bg-base-200/50">
          <div class="flex items-center justify-between">
            <span class="text-xs text-base-content/60">
              <.icon name="hero-lock-closed" class="w-3 h-3 inline" />
            </span>
            <button
              type="button"
              class="btn btn-sm btn-primary"
              phx-click="close"
              phx-target={@myself}
            >
              Close
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("close", _params, socket) do
    send(self(), {:close_modal, :edge_info})
    {:noreply, socket}
  end
end
