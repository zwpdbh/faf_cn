defmodule FafCn.EcoEngine.ObserverTest do
  @moduledoc """
  Tests for Observer Agent - the world state keeper.

  ## Observer Features

  ### State Management
  - Tracks mass/energy storage levels (current and max capacity)
  - Tracks income rates (mass/energy per tick from mexes/pgens)
  - Tracks drain rates (mass/energy per tick consumed by builds)
  - Maintains simulation tick counter

  ### Tick Advancement
  - `tick/1`: Advances simulation by one time unit
  - Applies income to storage (capped at max capacity)
  - Applies drain from storage (floored at zero)
  - Detects and returns warning conditions after each tick

  ### Warning Detection (UI Alerts like in-game)
  - `:mass_overflow` - Mass storage >90% full with positive income
    (Player needs to spend mass or will waste it)
  - `:mass_stall` - Mass drain exceeds available (storage + income)
    (Build will pause due to lack of mass)
  - `:energy_overflow` - Net energy gain >20% of production
    (Player is wasting energy, should build more or reduce production)
  - `:energy_stall` - Energy drain exceeds available (storage + income)
    (Build will pause due to lack of energy)

  ### Consumption Tracking
  - `apply_consumption/3`: Records upcoming drain from active builds
  - Called by Builder agent before tick to set expected consumption

  ### Stats Reporting
  - `get_stats/1`: Returns complete eco snapshot for Manager decision-making
  """
  use ExUnit.Case, async: true

  alias FafCn.EcoEngine.Observer

  describe "new/1 - Initialization" do
    @doc """
    Test: Observer creates with FAF ACU starting defaults.

    These are the standard starting values in FAF:
    - Mass: 650/650 (ACU default mass storage)
    - Energy: 2500/2500 (ACU default energy storage)
    - Income: 0 (no mexes/pgens at game start)
    - Drain: 0 (no active builds)
    - Tick: 0 (simulation start)
    """
    test "creates with FAF ACU defaults" do
      observer = Observer.new()

      # Standard FAF ACU starting values
      assert observer.mass_storage == Observer.default_mass_storage()
      assert observer.mass_capacity == Observer.default_mass_storage()
      assert observer.energy_storage == Observer.default_energy_storage()
      assert observer.energy_capacity == Observer.default_energy_storage()
      assert observer.mass_produce == 0
      assert observer.energy_produce == 0
      assert observer.mass_drain == 0
      assert observer.energy_drain == 0
      assert observer.tick == 0
    end

    @doc """
    Test: Observer can be initialized with custom eco conditions.

    Useful for testing scenarios where player already has:
    - Established economy (income from mexes/pgens)
    - Partial storage (spent some resources)
    - Specific max capacities (upgraded storage)
    """
    test "creates with custom values" do
      observer =
        Observer.new(%{
          mass_storage: 100,
          energy_storage: 500,
          mass_produce: 10,
          energy_produce: 100
        })

      assert observer.mass_storage == 100
      assert observer.energy_storage == 500
      assert observer.mass_produce == 10
      assert observer.energy_produce == 100
    end
  end

  describe "tick/1 - Time Advancement" do
    @doc """
    Test: Tick applies income and drain, returns warnings.

    When income equals drain, storage stays constant and no warnings trigger.
    This is the balanced state where eco is stable.

    Scenario: Player has +10 mass/s income and is spending exactly 10 mass/s on builds.
    Result: Mass stays at 100, no overflow or stall warnings.
    """
    test "applies income and returns empty warnings when balanced" do
      {observer, warnings} =
        Observer.new(%{
          mass_storage: 100,
          mass_produce: 10,
          energy_storage: 500,
          energy_produce: 100
        })
        |> Observer.apply_consumption(10, 100)
        |> Observer.tick()

      # Income = drain, storage unchanged, no warnings
      assert observer.mass_storage == 100
      assert observer.energy_storage == 500
      assert observer.tick == 1
      assert warnings == []
    end

    @doc """
    Test: Drain reduces storage when no income.

    Scenario: Player starts a build with no mexes (0 income).
    Mass storage decreases by drain amount each tick.

    Example: Starting ACU with default 650 mass builds a unit costing 5 mass/tick.
    After 1 tick: 650 - 5 = 645 mass remaining.
    """
    test "applies drain reducing storage" do
      {observer, _warnings} =
        Observer.new(%{
          mass_storage: 100,
          energy_storage: 500
        })
        |> Observer.apply_consumption(5, 50)
        |> Observer.tick()

      assert observer.mass_storage == 95
      assert observer.energy_storage == 450
    end

    @doc """
    Test: Both income and drain applied in same tick.

    Net change = income - drain

    Scenario: Player has +10 mass/s income and is spending 5 mass/s.
    Net gain: +5 mass per tick.

    Mass: 100 + 10 - 5 = 105
    Energy: 500 + 100 - 50 = 550
    """
    test "applies both income and drain correctly" do
      {observer, _warnings} =
        Observer.new(%{
          mass_storage: 100,
          mass_produce: 10,
          energy_storage: 500,
          energy_produce: 100
        })
        |> Observer.apply_consumption(5, 50)
        |> Observer.tick()

      assert observer.mass_storage == 105
      assert observer.energy_storage == 550
    end

    @doc """
    Test: Storage cannot exceed maximum capacity (overflow capped).

    Like in the game, when storage is full, additional income is wasted.

    Scenario: Mass storage near default max (640/650) with +20 income.
    After tick: Would be 660, but capped at 650. 10 mass is wasted.

    Warning: `:mass_overflow` triggered because storage >90% full with income.
    This alerts the player to spend mass before wasting it.
    """
    test "respects storage max and warns on overflow" do
      {observer, warnings} =
        Observer.new(%{
          mass_storage: 640,
          mass_capacity: Observer.default_mass_storage(),
          mass_produce: 20
        })
        |> Observer.tick()

      # 640 + 20 = 660, but max is 650 (10 mass wasted)
      assert observer.mass_storage == 650
      # Warn player that mass is being wasted
      assert :mass_overflow in warnings
    end

    @doc """
    Test: Storage cannot go below zero (stall floor).

    When resources run out, the build pauses - storage stays at 0.

    Scenario: Player has 10 mass, tries to spend 20 mass.
    After tick: Mass is 0 (not -10), build stalls.
    """
    test "storage cannot go below zero" do
      {observer, _warnings} =
        Observer.new(%{
          mass_storage: 10,
          energy_storage: 50
        })
        |> Observer.apply_consumption(20, 100)
        |> Observer.tick()

      # 10 - 20 would be -10, but floored at 0
      assert observer.mass_storage == 0
      assert observer.energy_storage == 0
    end
  end

  describe "warnings - UI Alert System" do
    @doc """
    Test: Mass overflow warning when storage has significant mass.

    Triggers when:
    - Storage >40% of max capacity
    - AND income is positive (more mass coming)

    This indicates the player has mass available to spend and should
    use it rather than letting it accumulate.
    """
    test "detects mass overflow when >40% full with income" do
      {observer, warnings} =
        Observer.new(%{
          mass_storage: 260,
          mass_capacity: Observer.default_mass_storage(),
          mass_produce: 10
        })
        |> Observer.tick()

      # 260 > 40% of 650 (260), exactly at threshold
      assert observer.mass_storage == 270
      assert :mass_overflow in warnings
    end

    @doc """
    Test: No mass overflow warning when storage below threshold.

    Scenario: Storage at 200/650 (~31% of ACU default max).
    Below 40% threshold, no warning needed.
    """
    test "no mass overflow warning when storage below 40%" do
      {_observer, warnings} =
        Observer.new(%{
          mass_storage: 200,
          mass_capacity: Observer.default_mass_storage(),
          mass_produce: 10
        })
        |> Observer.tick()

      # 200 < 40% of 650 (260)
      assert :mass_overflow not in warnings
    end

    @doc """
    Test: Mass stall warning when build can't be sustained.

    Triggers when: drain > (storage + income)

    Example: Player tries to build something costing 200 mass/tick,
    but only has 100 mass stored and 5 income = 105 available.

    Game UI would flash: "INSUFFICIENT MASS"
    Build will pause until more mass is available.
    """
    test "detects mass stall when drain exceeds available resources" do
      {_observer, warnings} =
        Observer.new(%{
          mass_storage: 100,
          mass_produce: 5
        })
        |> Observer.apply_consumption(200, 0)
        |> Observer.tick()

      # Drain 200 > Storage 100 + Income 5 = 105 available
      assert :mass_stall in warnings
    end

    @doc """
    Test: Energy overflow warning when producing too much.

    Triggers when: net gain (income - drain) > 20% of production

    This indicates player is wasting energy by over-building pgens.
    The excess energy is just filling storage unnecessarily.

    At threshold: 100 income - 80 drain = 20 net = 20% of income (no warning)
    Over threshold: 100 income - 79 drain = 21 net = 21% of income (warning)

    Game UI would flash: "EXCESS ENERGY"
    Player should build more units or reduce pgen production.
    """
    test "detects energy overflow when net gain >20% of production" do
      # At threshold: net gain = 100 - 80 = 20 = 20% of income (exactly at limit, no warning)
      {_observer, warnings} =
        Observer.new(%{
          energy_produce: 100,
          energy_storage: 2000,
          energy_capacity: Observer.default_energy_storage()
        })
        |> Observer.apply_consumption(0, 80)
        |> Observer.tick()

      assert :energy_overflow not in warnings

      # Over threshold: net gain = 100 - 79 = 21 > 20% of income (warning)
      {_observer, warnings} =
        Observer.new(%{
          energy_produce: 100,
          energy_storage: 2000,
          energy_capacity: Observer.default_energy_storage()
        })
        |> Observer.apply_consumption(0, 79)
        |> Observer.tick()

      # Net gain 21 > 100 * 0.2 = 20
      assert :energy_overflow in warnings
    end

    @doc """
    Test: Energy stall warning when build consumes too much energy.

    Similar to mass stall - build requires more energy than available.

    Example: Player has 500 energy stored, +10 income,
    but build costs 1000 energy/tick.

    Game UI would flash: "INSUFFICIENT ENERGY"
    Build pauses until more energy accumulates or more pgens built.
    """
    test "detects energy stall when drain exceeds available resources" do
      {_observer, warnings} =
        Observer.new(%{
          energy_storage: 500,
          energy_produce: 10
        })
        |> Observer.apply_consumption(0, 1000)
        |> Observer.tick()

      # Drain 1000 > Storage 500 + Income 10 = 510 available
      assert :energy_stall in warnings
    end

    @doc """
    Test: Multiple warnings can trigger simultaneously.

    Scenario: Player tries to build expensive units without enough eco.
    Both mass AND energy drains exceed available resources.

    Result: `[:mass_stall, :energy_stall]` warnings returned.
    Manager should pause build or order income structures.
    """
    test "can have multiple warnings at once" do
      {_observer, warnings} =
        Observer.new(%{
          mass_storage: 100,
          mass_produce: 10,
          energy_storage: 200,
          energy_produce: 100
        })
        |> Observer.apply_consumption(200, 1000)
        |> Observer.tick()

      # Both stall warnings triggered
      # mass: drain 200 > storage 100 + income 10 = 110 available
      # energy: drain 1000 > storage 200 + income 100 = 300 available
      assert :mass_stall in warnings
      assert :energy_stall in warnings
    end
  end

  describe "apply_consumption/3 - Builder Integration" do
    @doc """
    Test: Builder reports upcoming consumption before tick.

    Builder calculates how much mass/energy it will consume based on:
    - Build power available (engineers assisting)
    - Unit build cost and time

    Observer records this to apply during next tick.

    Example: Building a unit with 5 mass/tick and 50 energy/tick cost.
    """
    test "records drain values from Builder" do
      observer =
        Observer.new()
        |> Observer.apply_consumption(5, 50)

      assert observer.mass_drain == 5
      assert observer.energy_drain == 50
    end
  end

  describe "get_stats/1 - Manager Reporting" do
    @doc """
    Test: Observer provides complete eco snapshot to Manager.

    Manager uses these stats each tick to make decisions:
    - Can we afford the goal unit?
    - Should we build income structures first?
    - Are we resource limited or build power limited?

    Returns all current values including drain and net rates for decision-making.

    Net rates (like game UI shows):
    - Positive = gaining resources
    - Negative = losing resources (drain > income)
    """
    test "returns complete eco stats including net rates for Manager decisions" do
      observer =
        Observer.new(%{
          mass_storage: 100,
          energy_storage: 500,
          mass_produce: 10,
          energy_produce: 100
        })
        |> Observer.apply_consumption(5, 50)

      stats = Observer.get_stats(observer)

      assert stats.tick == 0
      assert stats.mass_storage == 100
      assert stats.energy_storage == 500
      assert stats.mass_produce == 10
      assert stats.energy_produce == 100
      assert stats.mass_drain == 5
      assert stats.energy_drain == 50
      # Net rates like game UI shows (can be negative)
      # 10 income - 5 drain
      assert stats.mass_net == 5
      # 100 income - 50 drain
      assert stats.energy_net == 50
    end

    @doc """
    Test: Net rates can be negative when drain exceeds income.

    This is what the game UI shows as "Mass: -5/s" indicating
    the player is spending more than they produce.
    """
    test "returns negative net rates when drain exceeds income" do
      observer =
        Observer.new(%{
          mass_produce: 10,
          energy_produce: 100
        })
        |> Observer.apply_consumption(20, 200)

      stats = Observer.get_stats(observer)

      # Negative net = losing resources faster than gaining
      # 10 - 20 = -10
      assert stats.mass_net == -10
      # 100 - 200 = -100
      assert stats.energy_net == -100
    end
  end
end
