defmodule FafCnWeb.EcoPredictionLive do
  @moduledoc """
  LiveView for Eco Prediction with real-time simulation.
  """
  use FafCnWeb, :live_view

  alias FafCn.EcoEngine.{Config, Simulator, State}

  on_mount {FafCnWeb.UserAuth, :mount_current_user}

  # 100ms = 1 game second
  @tick_interval 100
  # 20 minutes default
  @default_max_duration 1200

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Eco Prediction")
      |> assign_simulation_defaults()

    {:ok, socket}
  end

  defp assign_simulation_defaults(socket) do
    socket
    |> assign(:t1_mex, 2)
    |> assign(:t2_mex, 0)
    |> assign(:t3_mex, 0)
    |> assign(:mass_storage, 650)
    |> assign(:energy_storage, 2500)
    |> assign(:max_duration, @default_max_duration)
    # :idle, :running, :paused
    |> assign(:simulation_state, :idle)
    |> assign(:current_tick, 0)
    |> assign(:timer_ref, nil)
    |> assign(:chart_data, %{
      time: [],
      mass: [],
      energy: [],
      build_power: [],
      accumulated_mass: []
    })
    |> assign(:show_mass, true)
    |> assign(:show_energy, true)
    |> assign(:show_build_power, true)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <%!-- Header --%>
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-gray-900">Eco Prediction</h1>
          <p class="mt-2 text-gray-600">
            Simulate your economy over time. Watch how mass, energy, and build power change based on your mex setup.
          </p>
        </div>

        <div class="space-y-6">
          <%!-- Start Conditions Card --%>
          <div class="bg-white shadow rounded-lg p-6">
            <h2 class="text-lg font-medium text-gray-900 mb-4">Start Conditions</h2>

            <%!-- Mex Counts --%>
            <div class="space-y-4">
              <div class="grid grid-cols-3 md:grid-cols-6 gap-3">
                <div>
                  <label class="block text-xs font-medium text-gray-700 mb-1">T1 Mex</label>
                  <input
                    type="number"
                    min="0"
                    value={@t1_mex}
                    phx-change="update_t1_mex"
                    disabled={@simulation_state == :running}
                    class={[
                      "block w-full rounded-md shadow-sm text-sm",
                      @simulation_state == :running && "bg-gray-100",
                      @simulation_state != :running &&
                        "border-gray-300 focus:border-blue-500 focus:ring-blue-500"
                    ]}
                  />
                  <p class="mt-1 text-xs text-gray-500">+2/s</p>
                </div>
                <div>
                  <label class="block text-xs font-medium text-gray-700 mb-1">T2 Mex</label>
                  <input
                    type="number"
                    min="0"
                    value={@t2_mex}
                    phx-change="update_t2_mex"
                    disabled={@simulation_state == :running}
                    class={[
                      "block w-full rounded-md shadow-sm text-sm",
                      @simulation_state == :running && "bg-gray-100",
                      @simulation_state != :running &&
                        "border-gray-300 focus:border-blue-500 focus:ring-blue-500"
                    ]}
                  />
                  <p class="mt-1 text-xs text-gray-500">+6/s</p>
                </div>
                <div>
                  <label class="block text-xs font-medium text-gray-700 mb-1">T3 Mex</label>
                  <input
                    type="number"
                    min="0"
                    value={@t3_mex}
                    phx-change="update_t3_mex"
                    disabled={@simulation_state == :running}
                    class={[
                      "block w-full rounded-md shadow-sm text-sm",
                      @simulation_state == :running && "bg-gray-100",
                      @simulation_state != :running &&
                        "border-gray-300 focus:border-blue-500 focus:ring-blue-500"
                    ]}
                  />
                  <p class="mt-1 text-xs text-gray-500">+18/s</p>
                </div>
                <div>
                  <label class="block text-xs font-medium text-gray-700 mb-1">Mass Storage</label>
                  <input
                    type="number"
                    min="0"
                    value={@mass_storage}
                    phx-change="update_mass_storage"
                    disabled={@simulation_state == :running}
                    class={[
                      "block w-full rounded-md shadow-sm text-sm",
                      @simulation_state == :running && "bg-gray-100",
                      @simulation_state != :running &&
                        "border-gray-300 focus:border-blue-500 focus:ring-blue-500"
                    ]}
                  />
                </div>
                <div>
                  <label class="block text-xs font-medium text-gray-700 mb-1">Energy Storage</label>
                  <input
                    type="number"
                    min="0"
                    value={@energy_storage}
                    phx-change="update_energy_storage"
                    disabled={@simulation_state == :running}
                    class={[
                      "block w-full rounded-md shadow-sm text-sm",
                      @simulation_state == :running && "bg-gray-100",
                      @simulation_state != :running &&
                        "border-gray-300 focus:border-blue-500 focus:ring-blue-500"
                    ]}
                  />
                </div>
                <div>
                  <label class="block text-xs font-medium text-gray-700 mb-1">Max Duration (s)</label>
                  <input
                    type="number"
                    min="60"
                    max="3600"
                    value={@max_duration}
                    phx-change="update_max_duration"
                    disabled={@simulation_state == :running}
                    class={[
                      "block w-full rounded-md shadow-sm text-sm",
                      @simulation_state == :running && "bg-gray-100",
                      @simulation_state != :running &&
                        "border-gray-300 focus:border-blue-500 focus:ring-blue-500"
                    ]}
                  />
                  <p class="mt-1 text-xs text-gray-500">{div(@max_duration, 60)} min</p>
                </div>
              </div>
            </div>
          </div>

          <%!-- Simulation Result Card --%>
          <div class="bg-white shadow rounded-lg p-6">
            <%!-- Chart Header with Controls --%>
            <div class="flex flex-wrap items-center justify-between mb-4 gap-4">
              <h2 class="text-lg font-medium text-gray-900">Simulation Result</h2>

              <%!-- Chart Series Toggles --%>
              <div class="flex items-center gap-4 text-sm">
                <label class="flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={@show_mass}
                    phx-click="toggle_mass"
                    class="rounded border-gray-300 text-emerald-600 focus:ring-emerald-500"
                  />
                  <span class="ml-2 flex items-center">
                    <span class="w-3 h-3 rounded-full bg-emerald-500 mr-1"></span> Mass
                  </span>
                </label>
                <label class="flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={@show_energy}
                    phx-click="toggle_energy"
                    class="rounded border-gray-300 text-amber-500 focus:ring-amber-500"
                  />
                  <span class="ml-2 flex items-center">
                    <span class="w-3 h-3 rounded-full bg-amber-500 mr-1"></span> Energy
                  </span>
                </label>
                <label class="flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={@show_build_power}
                    phx-click="toggle_build_power"
                    class="rounded border-gray-300 text-blue-500 focus:ring-blue-500"
                  />
                  <span class="ml-2 flex items-center">
                    <span class="w-3 h-3 rounded-full bg-blue-500 mr-1"></span> Build Power
                  </span>
                </label>
              </div>
            </div>

            <%!-- Chart --%>
            <div
              id="eco-chart"
              phx-hook="EcoChart"
              phx-update="ignore"
              class="w-full h-96"
            />

            <%!-- Action Buttons --%>
            <div class="mt-6 flex items-center justify-center gap-4">
              <%= if @simulation_state == :idle do %>
                <button
                  phx-click="start_simulation"
                  class="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center"
                >
                  <.icon name="hero-play" class="w-5 h-5 mr-2" /> Run Simulation
                </button>
              <% end %>

              <%= if @simulation_state == :running do %>
                <button
                  phx-click="pause_simulation"
                  class="px-6 py-2 bg-amber-500 text-white rounded-lg hover:bg-amber-600 transition-colors flex items-center"
                >
                  <.icon name="hero-pause" class="w-5 h-5 mr-2" /> Pause
                </button>
              <% end %>

              <%= if @simulation_state == :paused do %>
                <button
                  phx-click="resume_simulation"
                  class="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center"
                >
                  <.icon name="hero-play" class="w-5 h-5 mr-2" /> Resume
                </button>
              <% end %>

              <button
                phx-click="reset_simulation"
                disabled={@simulation_state == :idle and @current_tick == 0}
                class={[
                  "px-6 py-2 rounded-lg transition-colors flex items-center",
                  (@simulation_state == :idle and @current_tick == 0) &&
                    "bg-gray-200 text-gray-400 cursor-not-allowed",
                  (@simulation_state != :idle or @current_tick > 0) &&
                    "bg-gray-600 text-white hover:bg-gray-700"
                ]}
              >
                <.icon name="hero-arrow-path" class="w-5 h-5 mr-2" /> Reset
              </button>
            </div>

            <%!-- Progress Info --%>
            <%= if @simulation_state != :idle or @current_tick > 0 do %>
              <div class="mt-4 text-center text-sm text-gray-500">
                Time: {@current_tick}s / {@max_duration}s
                <%= if @simulation_state == :running do %>
                  <span class="text-blue-600 ml-2">(Running)</span>
                <% end %>
                <%= if @simulation_state == :paused do %>
                  <span class="text-amber-600 ml-2">(Paused)</span>
                <% end %>
              </div>
            <% end %>
          </div>

          <%!-- Build Order Card --%>
          <div class="bg-white shadow rounded-lg p-6">
            <h2 class="text-lg font-medium text-gray-900 mb-4">Build Order</h2>
            <p class="text-sm text-gray-500">
              Build order support coming in Phase 03. Currently simulates mex income only.
            </p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # Event Handlers - Configuration Updates

  @impl true
  def handle_event("update_t1_mex", %{"value" => value}, socket) do
    {:noreply, assign(socket, :t1_mex, String.to_integer(value))}
  end

  @impl true
  def handle_event("update_t2_mex", %{"value" => value}, socket) do
    {:noreply, assign(socket, :t2_mex, String.to_integer(value))}
  end

  @impl true
  def handle_event("update_t3_mex", %{"value" => value}, socket) do
    {:noreply, assign(socket, :t3_mex, String.to_integer(value))}
  end

  @impl true
  def handle_event("update_mass_storage", %{"value" => value}, socket) do
    {:noreply, assign(socket, :mass_storage, String.to_integer(value))}
  end

  @impl true
  def handle_event("update_energy_storage", %{"value" => value}, socket) do
    {:noreply, assign(socket, :energy_storage, String.to_integer(value))}
  end

  @impl true
  def handle_event("update_max_duration", %{"value" => value}, socket) do
    duration =
      case Integer.parse(value) do
        {n, _} when n < 60 -> 60
        {n, _} when n > 3600 -> 3600
        {n, _} -> n
        :error -> @default_max_duration
      end

    {:noreply, assign(socket, :max_duration, duration)}
  end

  # Event Handlers - Chart Toggles

  @impl true
  def handle_event("toggle_mass", _params, socket) do
    new_val = !socket.assigns.show_mass

    socket =
      socket
      |> assign(:show_mass, new_val)
      |> push_chart_data()

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_energy", _params, socket) do
    new_val = !socket.assigns.show_energy

    socket =
      socket
      |> assign(:show_energy, new_val)
      |> push_chart_data()

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_build_power", _params, socket) do
    new_val = !socket.assigns.show_build_power

    socket =
      socket
      |> assign(:show_build_power, new_val)
      |> push_chart_data()

    {:noreply, socket}
  end

  # Event Handlers - Simulation Control

  # Simulation State Machine
  # States: :idle -> :running <-> :paused -> :idle (via reset or completion)

  # Start simulation: only allowed from :idle state
  @impl true
  def handle_event("start_simulation", _params, %{assigns: %{simulation_state: :idle}} = socket) do
    config = create_config(socket.assigns)
    initial_state = Simulator.init(config)

    %{show_mass: show_mass, show_energy: show_energy, show_build_power: show_build_power} =
      socket.assigns

    # Get initial data point
    data_point = State.to_chart_data(initial_state)

    chart_data = %{
      time: [data_point.time],
      mass: [data_point.mass],
      energy: [data_point.energy],
      build_power: [data_point.build_power],
      accumulated_mass: [data_point.accumulated_mass]
    }

    socket =
      socket
      |> assign(:simulation_state, :running)
      |> assign(:current_tick, 1)
      |> assign(:simulator_state, initial_state)
      |> assign(:chart_data, chart_data)
      |> push_event("chart-data", %{
        time: chart_data.time,
        mass: chart_data.mass,
        energy: chart_data.energy,
        build_power: chart_data.build_power,
        show_mass: show_mass,
        show_energy: show_energy,
        show_build_power: show_build_power
      })
      |> schedule_tick()

    {:noreply, socket}
  end

  # Ignore start when not in :idle
  def handle_event("start_simulation", _params, socket), do: {:noreply, socket}

  # Pause simulation: only allowed from :running state
  @impl true
  def handle_event(
        "pause_simulation",
        _params,
        %{assigns: %{simulation_state: :running}} = socket
      ) do
    socket =
      socket
      |> assign(:simulation_state, :paused)
      |> cancel_tick()

    {:noreply, socket}
  end

  # Ignore pause when not running
  def handle_event("pause_simulation", _params, socket), do: {:noreply, socket}

  # Resume simulation: only allowed from :paused state
  @impl true
  def handle_event(
        "resume_simulation",
        _params,
        %{assigns: %{simulation_state: :paused}} = socket
      ) do
    socket =
      socket
      |> assign(:simulation_state, :running)
      |> schedule_tick()

    {:noreply, socket}
  end

  # Ignore resume when not paused
  def handle_event("resume_simulation", _params, socket), do: {:noreply, socket}

  # Reset simulation: allowed from any state
  @impl true
  def handle_event("reset_simulation", _params, socket) do
    socket =
      socket
      |> assign_simulation_defaults()
      |> cancel_tick()
      |> push_event("chart-data", %{
        time: [],
        mass: [],
        energy: [],
        build_power: [],
        show_mass: true,
        show_energy: true,
        show_build_power: true
      })

    {:noreply, socket}
  end

  # Tick handler: only process when running and have valid simulator state
  @impl true
  def handle_info(
        :tick,
        %{assigns: %{simulation_state: :running, simulator_state: %State{} = state}} = socket
      ) do
    %{
      current_tick: tick,
      chart_data: chart_data,
      max_duration: max_duration,
      show_mass: show_mass,
      show_energy: show_energy,
      show_build_power: show_build_power
    } = socket.assigns

    if tick >= max_duration do
      # Simulation complete - transition to idle
      socket =
        socket
        |> assign(:simulation_state, :idle)
        |> cancel_tick()

      {:noreply, socket}
    else
      # Calculate next state
      new_state = Simulator.tick(state)
      data_point = State.to_chart_data(new_state)

      # Append to chart data
      new_chart_data = %{
        time: chart_data.time ++ [data_point.time],
        mass: chart_data.mass ++ [data_point.mass],
        energy: chart_data.energy ++ [data_point.energy],
        build_power: chart_data.build_power ++ [data_point.build_power],
        accumulated_mass: chart_data.accumulated_mass ++ [data_point.accumulated_mass]
      }

      # Push chart data to client
      socket =
        socket
        |> assign(:current_tick, tick + 1)
        |> assign(:simulator_state, new_state)
        |> assign(:chart_data, new_chart_data)
        |> push_event("chart-data", %{
          time: new_chart_data.time,
          mass: new_chart_data.mass,
          energy: new_chart_data.energy,
          build_power: new_chart_data.build_power,
          show_mass: show_mass,
          show_energy: show_energy,
          show_build_power: show_build_power
        })
        |> schedule_tick()

      {:noreply, socket}
    end
  end

  # Ignore tick when not running or no simulator state (race condition after reset)
  def handle_info(:tick, socket), do: {:noreply, socket}

  # Helper Functions

  defp create_config(assigns) do
    Config.new(%{
      t1_mex_count: assigns.t1_mex,
      t2_mex_count: assigns.t2_mex,
      t3_mex_count: assigns.t3_mex,
      mass_storage: assigns.mass_storage,
      energy_storage: assigns.energy_storage
    })
  end

  defp push_chart_data(socket) do
    %{
      chart_data: chart_data,
      show_mass: show_mass,
      show_energy: show_energy,
      show_build_power: show_build_power
    } = socket.assigns

    push_event(socket, "chart-data", %{
      time: chart_data.time,
      mass: chart_data.mass,
      energy: chart_data.energy,
      build_power: chart_data.build_power,
      show_mass: show_mass,
      show_energy: show_energy,
      show_build_power: show_build_power
    })
  end

  defp schedule_tick(socket) do
    timer_ref = Process.send_after(self(), :tick, @tick_interval)
    assign(socket, :timer_ref, timer_ref)
  end

  defp cancel_tick(socket) do
    if socket.assigns.timer_ref do
      Process.cancel_timer(socket.assigns.timer_ref)
    end

    assign(socket, :timer_ref, nil)
  end
end
