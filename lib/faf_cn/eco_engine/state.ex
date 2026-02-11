defmodule FafCn.EcoEngine.State do
  @moduledoc """
  Represents the simulation state at a specific tick.
  """

  defstruct [
    :tick,
    :mass_storage,
    :energy_storage,
    :mass_income,
    :energy_income,
    :build_power,
    :accumulated_mass,
    :config
  ]

  @type t :: %__MODULE__{
    tick: non_neg_integer(),
    mass_storage: float(),
    energy_storage: float(),
    mass_income: non_neg_integer(),
    energy_income: non_neg_integer(),
    build_power: non_neg_integer(),
    accumulated_mass: float(),
    config: FafCn.EcoEngine.Config.t()
  }

  @doc """
  Creates initial state from config.
  """
  def initial(%FafCn.EcoEngine.Config{} = config) do
    %__MODULE__{
      tick: 0,
      mass_storage: config.mass_storage,
      energy_storage: config.energy_storage,
      mass_income: 0,
      energy_income: 0,
      build_power: 10,  # ACU build power
      accumulated_mass: config.mass_storage,
      config: config
    }
  end

  @doc """
  Converts state to chart data format.
  """
  def to_chart_data(%__MODULE__{} = state) do
    %{
      time: state.tick,
      mass: round(state.mass_storage),
      energy: round(state.energy_storage),
      build_power: state.build_power,
      accumulated_mass: round(state.accumulated_mass)
    }
  end
end
