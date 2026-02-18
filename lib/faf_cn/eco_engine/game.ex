defmodule FafCn.EcoEngine.Game do
  @moduledoc """
  Game - The world state for eco-build simulation.

  Stores only the current status, no logic:
  - Resource storage (mass, energy)
  - Resource production per second
  - Resource drain per second (set by Player)

  ## Tick Cycle (1 second)

  1. Add production (mass_produce_per_sec, energy_produce_per_sec)
  2. Subtract drain (mass_drain_per_sec, energy_drain_per_sec)
  3. Return updated state
  """

  defstruct [
    :mass_storage,
    :energy_storage,
    :mass_produce_per_sec,
    :energy_produce_per_sec,
    :mass_drain_per_sec,
    :energy_drain_per_sec
  ]

  @type t :: %__MODULE__{
    mass_storage: integer(),
    energy_storage: integer(),
    mass_produce_per_sec: integer(),
    energy_produce_per_sec: integer(),
    mass_drain_per_sec: integer(),
    energy_drain_per_sec: integer()
  }

  @doc """
  Create new game state.
  """
  def new(opts \\ %{}) do
    %__MODULE__{
      mass_storage: opts[:mass_storage] || 0,
      energy_storage: opts[:energy_storage] || 0,
      mass_produce_per_sec: opts[:mass_produce_per_sec] || 0,
      energy_produce_per_sec: opts[:energy_produce_per_sec] || 0,
      mass_drain_per_sec: 0,
      energy_drain_per_sec: 0
    }
  end

  @doc """
  Set resource drain rates (called by Player when starting build).
  """
  def set_drain(game, mass_drain_per_sec, energy_drain_per_sec) do
    %{
      game
      | mass_drain_per_sec: mass_drain_per_sec,
        energy_drain_per_sec: energy_drain_per_sec
    }
  end

  @doc """
  Clear drain rates (called when build completes or cancelled).
  """
  def clear_drain(game) do
    %{game | mass_drain_per_sec: 0, energy_drain_per_sec: 0}
  end

  @doc """
  Advance game by one tick (1 second).

  Returns updated game state.
  """
  def tick(game) do
    new_mass =
      game.mass_storage + game.mass_produce_per_sec - game.mass_drain_per_sec

    new_energy =
      game.energy_storage + game.energy_produce_per_sec -
        game.energy_drain_per_sec

    %{
      game
      | mass_storage: max(new_mass, 0),
        energy_storage: max(new_energy, 0)
    }
  end

  @doc """
  Check if game can afford current drain rates.
  """
  def can_afford?(game) do
    game.mass_storage >= game.mass_drain_per_sec and
      game.energy_storage >= game.energy_drain_per_sec
  end

  @doc """
  Get current status summary.
  """
  def status(game) do
    %{
      mass_storage: game.mass_storage,
      energy_storage: game.energy_storage,
      mass_produce_per_sec: game.mass_produce_per_sec,
      energy_produce_per_sec: game.energy_produce_per_sec,
      mass_drain_per_sec: game.mass_drain_per_sec,
      energy_drain_per_sec: game.energy_drain_per_sec,
      mass_net_per_sec:
        game.mass_produce_per_sec - game.mass_drain_per_sec,
      energy_net_per_sec:
        game.energy_produce_per_sec - game.energy_drain_per_sec,
      draining: game.mass_drain_per_sec > 0
    }
  end
end
