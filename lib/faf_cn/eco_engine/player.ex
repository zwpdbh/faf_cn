defmodule FafCn.EcoEngine.Player do
  @moduledoc """
  Player - The decision maker.

  Stores:
  - Target unit stats (mass, power, build_time)
  - Build power (BP from engineers)
  - Idle status (are we building or not?)

  ## Responsibilities

  1. Calculate drain rates based on target unit and BP
  2. Track if currently building (idle: false) or not (idle: true)
  3. Decide when to start/stop building
  """

  defstruct [
    :target_mass,
    :target_power,
    :target_build_time,
    :build_power,
    :idle
  ]

  @type t :: %__MODULE__{
    target_mass: integer() | nil,
    target_power: integer() | nil,
    target_build_time: integer() | nil,
    build_power: integer(),
    idle: boolean()
  }

  @doc """
  Create new Player.

  ## Options
  - target_mass: Mass cost of unit to build
  - target_power: Energy cost of unit to build
  - target_build_time: Build time of unit
  - build_power: Total BP from engineers (default: 0)
  - idle: Whether player is idle (default: true)
  """
  def new(opts \\ %{}) do
    %__MODULE__{
      target_mass: opts[:target_mass],
      target_power: opts[:target_power],
      target_build_time: opts[:target_build_time],
      build_power: opts[:build_power] || 0,
      idle: opts[:idle] != false
    }
  end

  @doc """
  Start building (set to not idle).
  """
  def start_build(player) do
    %{player | idle: false}
  end

  @doc """
  Stop building (set to idle).
  """
  def stop_build(player) do
    %{player | idle: true}
  end

  @doc """
  Calculate mass drain per second based on target and BP.

  Returns 0.0 if idle or no target set.

  Formula: (target_mass / target_build_time) * build_power
  """
  def mass_drain_per_sec(player) do
    if player.idle do
      0.0
    else
      calculate_drain(player.target_mass, player.target_build_time, player.build_power)
    end
  end

  @doc """
  Calculate energy drain per second based on target and BP.

  Returns 0.0 if idle or no target set.

  Formula: (target_power / target_build_time) * build_power
  """
  def energy_drain_per_sec(player) do
    if player.idle do
      0.0
    else
      calculate_drain(player.target_power, player.target_build_time, player.build_power)
    end
  end

  @doc """
  Check if currently building.
  """
  def building?(player) do
    not player.idle
  end

  @doc """
  Check if has a target set.
  """
  def has_target?(player) do
    player.target_mass != nil and player.target_power != nil and
      player.target_build_time != nil
  end

  @doc """
  Get player status summary.
  """
  def status(player) do
    %{
      target_mass: player.target_mass,
      target_power: player.target_power,
      target_build_time: player.target_build_time,
      build_power: player.build_power,
      idle: player.idle,
      building: building?(player),
      has_target: has_target?(player),
      mass_drain_per_sec: mass_drain_per_sec(player),
      energy_drain_per_sec: energy_drain_per_sec(player)
    }
  end

  # Private functions

  defp calculate_drain(cost, build_time, build_power) do
    if cost && build_time && build_time > 0 do
      cost * build_power / build_time
    else
      0.0
    end
  end
end
