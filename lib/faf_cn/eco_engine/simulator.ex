defmodule FafCn.EcoEngine.Simulator do
  @moduledoc """
  Main simulation engine for eco prediction.
  Pure functions for tick-based simulation.
  """

  alias FafCn.EcoEngine.{Config, State}

  @doc """
  Creates initial state from config.
  """
  def init(%Config{} = config) do
    State.initial(config)
  end

  @doc """
  Advances simulation by one tick.
  Currently simplified: only calculates mex income.
  """
  def tick(%State{} = state) do
    mass_income = Config.mass_income_per_tick(state.config)
    
    # Simplified: assume energy is sufficient
    # In full version, would calculate energy income/drain
    energy_income = 0
    
    new_mass = state.mass_storage + mass_income
    new_energy = state.energy_storage + energy_income
    new_accumulated = state.accumulated_mass + mass_income
    
    %State{
      state
      | tick: state.tick + 1,
        mass_storage: new_mass,
        energy_storage: new_energy,
        mass_income: mass_income,
        energy_income: energy_income,
        accumulated_mass: new_accumulated
    }
  end

  @doc """
  Runs simulation for specified number of ticks.
  Returns list of states.
  """
  def run(%Config{} = config, duration_ticks) do
    initial = init(config)
    
    Enum.reduce(1..duration_ticks, [initial], fn _tick, [current | _] = acc ->
      new_state = tick(current)
      [new_state | acc]
    end)
    |> Enum.reverse()
  end

  @doc """
  Runs simulation and returns chart data format.
  """
  def run_chart_data(%Config{} = config, duration_ticks) do
    config
    |> run(duration_ticks)
    |> Enum.map(&State.to_chart_data/1)
  end
end
