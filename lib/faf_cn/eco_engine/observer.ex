defmodule FafCn.EcoEngine.Observer do
  @moduledoc """
  Observer Agent - maintains world state and drives simulation ticks.

  Responsibilities:
  - Track current eco status (mass/energy storage, income, drain)
  - Advance simulation by one tick (apply income, subtract drain)
  - Detect warnings (overflow, stall) like UI alerts in game
  - Report stats and warnings to Manager
  """

  defstruct [
    :mass_storage,
    :energy_storage,
    :mass_capacity,
    :energy_capacity,
    :mass_produce,
    :energy_produce,
    :mass_drain,
    :energy_drain,
    :tick
  ]

  @type t :: %__MODULE__{
          mass_storage: integer(),
          energy_storage: integer(),
          mass_capacity: integer(),
          energy_capacity: integer(),
          mass_produce: integer(),
          energy_produce: integer(),
          mass_drain: integer(),
          energy_drain: integer(),
          tick: non_neg_integer()
        }

  @type warning ::
          :mass_overflow | :mass_stall | :energy_overflow | :energy_stall

  # Standard FAF ACU starting storage values
  # These match the default starting economy in the game
  @default_mass_storage 650
  @default_energy_storage 2500

  @doc """
  Returns the default mass storage value (FAF ACU starting mass).
  """
  def default_mass_storage, do: @default_mass_storage

  @doc """
  Returns the default energy storage value (FAF ACU starting energy).
  """
  def default_energy_storage, do: @default_energy_storage

  @doc """
  Create new Observer with initial eco conditions.

  ## Default Values (FAF ACU Starting Stats)

  - mass_storage: #{@default_mass_storage}
  - energy_storage: #{@default_energy_storage}
  - mass_capacity: #{@default_mass_storage}
  - energy_capacity: #{@default_energy_storage}
  - mass_produce: 0
  - energy_produce: 0

  Pass custom values to override (e.g., after building some mexes).
  """
  def new(attrs \\ %{}) do
    %__MODULE__{
      mass_storage: attrs[:mass_storage] || @default_mass_storage,
      energy_storage: attrs[:energy_storage] || @default_energy_storage,
      mass_capacity: attrs[:mass_capacity] || @default_mass_storage,
      energy_capacity: attrs[:energy_capacity] || @default_energy_storage,
      mass_produce: attrs[:mass_produce] || 0,
      energy_produce: attrs[:energy_produce] || 0,
      mass_drain: 0,
      energy_drain: 0,
      tick: 0
    }
  end

  @doc """
  Advance simulation by one tick.

  Applies income and subtracts drain from storage.
  Updates tick counter.
  Returns {new_observer, warnings} tuple.
  """
  def tick(observer) do
    new_observer =
      observer
      |> apply_income()
      |> apply_drain()
      |> increment_tick()

    warnings = detect_warnings(new_observer)

    {new_observer, warnings}
  end

  @doc """
  Apply consumption from Builder for upcoming tick.

  Call this when Builder reports what it will consume.
  """
  def apply_consumption(observer, mass_drain, energy_drain) do
    %{observer | mass_drain: mass_drain, energy_drain: energy_drain}
  end

  @doc """
  Get current eco stats for reporting to Manager.

  Includes net rates like the game UI shows:
  - mass_net: income - drain (can be negative)
  - energy_net: income - drain (can be negative)
  """
  def get_stats(observer) do
    %{
      tick: observer.tick,
      mass_storage: observer.mass_storage,
      energy_storage: observer.energy_storage,
      mass_capacity: observer.mass_capacity,
      energy_capacity: observer.energy_capacity,
      mass_produce: observer.mass_produce,
      energy_produce: observer.energy_produce,
      mass_drain: observer.mass_drain,
      energy_drain: observer.energy_drain,
      mass_net: observer.mass_produce - observer.mass_drain,
      energy_net: observer.energy_produce - observer.energy_drain
    }
  end

  # Private functions

  defp apply_income(observer) do
    new_mass =
      min(
        observer.mass_storage + observer.mass_produce,
        observer.mass_capacity
      )

    new_energy =
      min(
        observer.energy_storage + observer.energy_produce,
        observer.energy_capacity
      )

    %{observer | mass_storage: new_mass, energy_storage: new_energy}
  end

  defp apply_drain(observer) do
    new_mass = max(observer.mass_storage - observer.mass_drain, 0)
    new_energy = max(observer.energy_storage - observer.energy_drain, 0)

    %{observer | mass_storage: new_mass, energy_storage: new_energy}
  end

  defp increment_tick(observer) do
    %{observer | tick: observer.tick + 1}
  end

  defp detect_warnings(observer) do
    []
    |> maybe_add_mass_overflow_warning(observer)
    |> maybe_add_mass_stall_warning(observer)
    |> maybe_add_energy_overflow_warning(observer)
    |> maybe_add_energy_stall_warning(observer)
  end

  defp maybe_add_mass_overflow_warning(warnings, observer) do
    # Warning when storage has significant mass with positive production
    # Threshold: >40% full with positive production (indicates need to spend)
    threshold = trunc(observer.mass_capacity * 0.4)

    if observer.mass_storage >= threshold and observer.mass_produce > 0 do
      [:mass_overflow | warnings]
    else
      warnings
    end
  end

  defp maybe_add_mass_stall_warning(warnings, observer) do
    # Warning when drain exceeds available resources + production
    # This means we'll run out of mass
    if observer.mass_drain > observer.mass_storage + observer.mass_produce do
      [:mass_stall | warnings]
    else
      warnings
    end
  end

  defp maybe_add_energy_overflow_warning(warnings, observer) do
    # Energy overflow: net gain (produce - drain) is >20% of production
    # This means player is producing energy faster than they can use it
    net_gain = observer.energy_produce - observer.energy_drain

    if observer.energy_produce > 0 and net_gain > trunc(observer.energy_produce * 0.2) do
      [:energy_overflow | warnings]
    else
      warnings
    end
  end

  defp maybe_add_energy_stall_warning(warnings, observer) do
    if observer.energy_drain > observer.energy_storage + observer.energy_produce do
      [:energy_stall | warnings]
    else
      warnings
    end
  end
end
