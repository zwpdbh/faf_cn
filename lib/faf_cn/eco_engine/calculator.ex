defmodule FafCn.EcoEngine.Calculator do
  @moduledoc """
  Goal-oriented eco simulation calculator.

  Calculates the optimal build order and time to achieve a goal
  given initial eco conditions.
  """

  # TODO: Will use these for full simulation implementation
  # alias FafCn.EcoEngine.{Simulator, State}

  @doc """
  Calculates total build power from engineers.

  Formula: (T1 × 5) + (T2 × 10) + (T3 × 15)
  """
  def calculate_build_power(engineers) do
    # TODO: Implement
    t1_bp = (engineers.t1 || 0) * 5
    t2_bp = (engineers.t2 || 0) * 10
    t3_bp = (engineers.t3 || 0) * 15

    t1_bp + t2_bp + t3_bp
  end

  @doc """
  Calculates build time in seconds given build time and build power.

  Returns rounded up integer seconds, or :infinity if BP is 0.
  """
  def calculate_build_time(build_time_ticks, build_power) do
    # TODO: Implement
    if build_power <= 0 do
      :infinity
    else
      seconds = build_time_ticks / build_power
      ceil(seconds)
    end
  end

  @doc """
  Calculates time to accumulate required resources.

  Formula: max(0, (required - current)) / income
  Returns :infinity if income is 0 and more resources are needed.
  """
  def calculate_resource_time(required, current, income) do
    # TODO: Implement
    needed = max(0, required - current)

    cond do
      needed <= 0 -> 0
      income <= 0 -> :infinity
      true -> ceil(needed / income)
    end
  end

  @doc """
  Main entry point: runs simulation to calculate build order and time.

  ## Parameters
    - initial_eco: Map with mass_income, energy_income, mass_storage, etc.
    - goal: Map with unit, quantity, include_factory

  ## Returns
    - %{completion_time, build_order, chart_data, milestones}
  """
  def run(initial_eco, goal) do
    # TODO: Full implementation
    # For now, return a placeholder to make tests compile

    build_power = calculate_build_power(initial_eco.engineers)

    # Simple calculation without storage limits for now
    unit = goal.unit
    total_mass = unit.build_cost_mass * goal.quantity
    total_energy = unit.build_cost_energy * goal.quantity
    total_build_time = unit.build_time * goal.quantity

    mass_time =
      calculate_resource_time(total_mass, initial_eco.mass_storage, initial_eco.mass_income)

    energy_time =
      calculate_resource_time(total_energy, initial_eco.energy_storage, initial_eco.energy_income)

    build_time = calculate_build_time(total_build_time, build_power)

    completion_time = max_time([mass_time, energy_time, build_time])

    %{
      completion_time: completion_time,
      build_order: [%{unit: unit.description, start_time: 0, end_time: completion_time}],
      chart_data: %{
        time: [0, completion_time],
        mass: [
          initial_eco.mass_storage,
          initial_eco.mass_storage + initial_eco.mass_income * completion_time
        ],
        energy: [
          initial_eco.energy_storage,
          initial_eco.energy_storage + initial_eco.energy_income * completion_time
        ]
      },
      milestones: [
        %{time: 0, label: "Start", type: :start},
        %{time: completion_time, label: "Goal Complete", type: :goal_complete}
      ]
    }
  end

  # Helper to find max time, handling :infinity
  defp max_time(times) do
    times
    |> Enum.reduce(0, fn
      :infinity, _acc -> :infinity
      _time, :infinity -> :infinity
      time, acc -> max(time, acc)
    end)
  end
end
