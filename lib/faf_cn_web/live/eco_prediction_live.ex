defmodule FafCnWeb.EcoPredictionLive do
  @moduledoc """
  LiveView for Eco Prediction - simulates economy over time.
  """
  use FafCnWeb, :live_view

  on_mount {FafCnWeb.UserAuth, :mount_current_user}

  @impl true
  def mount(_params, _session, socket) do
    # Generate demo data for the chart
    # Simulating: 2 T1 mex (4 mass/sec), build some units
    chart_data = generate_demo_data()
    
    socket =
      socket
      |> assign(:page_title, "Eco Prediction")
      |> assign(:chart_data, chart_data)
      |> assign(:initial_mex, 2)
      |> assign(:initial_mass, 650)
      |> assign(:initial_energy, 2500)

    {:ok, socket}
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
            Simulate your economy over time. See how mass, energy, and build power change based on your build order.
          </p>
        </div>

        <%!-- Demo Notice --%>
        <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-8">
          <div class="flex">
            <div class="flex-shrink-0">
              <.icon name="hero-information-circle" class="h-5 w-5 text-blue-400" />
            </div>
            <div class="ml-3">
              <h3 class="text-sm font-medium text-blue-800">Demo Mode</h3>
              <div class="mt-2 text-sm text-blue-700">
                <p>
                  This is a demo showing the chart visualization. Full simulation features coming soon!
                  Currently showing: 2 T1 Mex (+4 mass/sec), building 3 T1 engineers.
                </p>
              </div>
            </div>
          </div>
        </div>

        <%!-- Starting Conditions Form (Visual Only for Demo) --%>
        <div class="bg-white shadow rounded-lg p-6 mb-8">
          <h2 class="text-lg font-medium text-gray-900 mb-4">Starting Conditions</h2>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700">T1 Mass Extractors</label>
              <input
                type="number"
                value={@initial_mex}
                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                disabled
              />
              <p class="mt-1 text-xs text-gray-500">+4 mass/sec</p>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700">Starting Mass</label>
              <input
                type="number"
                value={@initial_mass}
                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                disabled
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700">Starting Energy</label>
              <input
                type="number"
                value={@initial_energy}
                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                disabled
              />
            </div>
          </div>
        </div>

        <%!-- Build Order (Visual Only for Demo) --%>
        <div class="bg-white shadow rounded-lg p-6 mb-8">
          <h2 class="text-lg font-medium text-gray-900 mb-4">Build Order</h2>
          <div class="space-y-2">
            <div class="flex items-center justify-between p-3 bg-gray-50 rounded-md">
              <div class="flex items-center space-x-3">
                <div class="w-10 h-10 rounded bg-blue-100 flex items-center justify-center">
                  <.icon name="hero-wrench" class="h-5 w-5 text-blue-600" />
                </div>
                <div>
                  <p class="font-medium text-gray-900">T1 Engineer</p>
                  <p class="text-sm text-gray-500">UEL0105 - 52 mass, 260 energy</p>
                </div>
              </div>
              <span class="text-sm text-gray-500">× 3</span>
            </div>
          </div>
        </div>

        <%!-- Chart --%>
        <div class="bg-white shadow rounded-lg p-6">
          <h2 class="text-lg font-medium text-gray-900 mb-4">Simulation Result</h2>
          <div
            id="eco-chart"
            phx-hook="EcoChart"
            data-time={Jason.encode!(@chart_data.time)}
            data-mass={Jason.encode!(@chart_data.mass)}
            data-energy={Jason.encode!(@chart_data.energy)}
            data-build-power={Jason.encode!(@chart_data.build_power)}
            class="w-full h-96"
          />
        </div>

        <%!-- Legend --%>
        <div class="mt-6 flex flex-wrap justify-center gap-6 text-sm">
          <div class="flex items-center">
            <span class="w-4 h-4 rounded-full bg-emerald-500 mr-2"></span>
            <span class="text-gray-700">Mass</span>
          </div>
          <div class="flex items-center">
            <span class="w-4 h-4 rounded-full bg-amber-500 mr-2"></span>
            <span class="text-gray-700">Energy</span>
          </div>
          <div class="flex items-center">
            <span class="w-4 h-4 rounded-full bg-blue-500 mr-2"></span>
            <span class="text-gray-700">Build Power</span>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # Generate demo data for the chart
  # Simulates: 2 T1 mex, building 3 T1 engineers
  defp generate_demo_data do
    duration = 300  # 5 minutes
    tick_interval = 5  # Every 5 seconds
    
    time = Enum.to_list(0..duration//tick_interval)
    
    # Initial values
    initial_mass = 650
    initial_energy = 2500
    initial_build_power = 10  # ACU
    
    # Income (2 T1 mex = 4 mass/sec)
    mass_income = 4
    
    # Build queue: 3 T1 engineers
    # Each: 52 mass, 260 energy, 260 build time, +5 build power when done
    builds = [
      %{start: 0, cost: 52, build_time: 260, build_power: 5},
      %{start: 260, cost: 52, build_time: 260, build_power: 5},
      %{start: 520, cost: 52, build_time: 260, build_power: 5}
    ]
    
    # Simulate tick by tick
    {mass_values, energy_values, build_power_values} = 
      Enum.reduce(time, {[], [], []}, fn t, {mass_acc, energy_acc, bp_acc} ->
        # Calculate mass (income minus build costs)
        mass = initial_mass + t * mass_income
        
        # Deduct build costs
        mass = mass - sum_build_costs(builds, t)
        
        # Energy stays relatively flat (simplified)
        energy = initial_energy
        
        # Build power increases as engineers complete
        build_power = initial_build_power + sum_build_power(builds, t)
        
        {[mass | mass_acc], [energy | energy_acc], [build_power | bp_acc]}
      end)
    
    %{
      time: time,
      mass: Enum.reverse(mass_values),
      energy: Enum.reverse(energy_values),
      build_power: Enum.reverse(build_power_values)
    }
  end
  
  defp sum_build_costs(builds, current_time) do
    builds
    |> Enum.filter(&(&1.start <= current_time))
    |> Enum.map(& &1.cost)
    |> Enum.sum()
  end
  
  defp sum_build_power(builds, current_time) do
    builds
    |> Enum.filter(&(&1.start + &1.build_time <= current_time))
    |> Enum.map(& &1.build_power)
    |> Enum.sum()
  end
end
