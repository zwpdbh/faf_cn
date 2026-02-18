defmodule FafCn.EcoEngine.BuilderTest do
  @moduledoc """
  Tests for Builder Agent - executes build orders and tracks progress.

  ## Build Progress Model

  Progress is tracked in "build seconds completed" against unit's build_time:
  - 0 progress = just started
  - 50% progress = build_time / 2
  - 100% progress = build_time (complete)

  ## Build Power (BP) Tiers

  - T1 Engineer: 2 BP
  - T2 Engineer: 5 BP
  - T3 Engineer: 15 BP

  Total BP determines how fast units build (progress per tick).
  """
  use ExUnit.Case, async: true

  alias FafCn.EcoEngine.Builder

  # Sample units for testing (like T1 engineer)
  @t1_engineer %{
    unit_id: "UEL0105",
    name: "Engineer",
    build_time: 130,
    build_cost_mass: 52,
    build_cost_energy: 260
  }

  describe "new/1 - Initialization" do
    @doc """
    Test: Builder creates with default (no engineers).

    No build power means cannot build anything.
    """
    test "creates with zero BP by default" do
      builder = Builder.new()

      assert builder.total_bp == 0
      assert builder.status == :idle
      assert builder.current_target == nil
    end

    @doc """
    Test: Builder calculates total BP from engineers.

    Example: 5 T1 engineers = 5 × 2 BP = 10 total BP
    """
    test "calculates BP from T1 engineers" do
      builder = Builder.new(%{engineers: %{t1: 5, t2: 0, t3: 0}})

      assert builder.total_bp == 10
    end

    @doc """
    Test: Builder calculates BP from mixed engineer tiers.

    Example: 2 T1 (4 BP) + 1 T2 (5 BP) + 1 T3 (15 BP) = 24 total BP
    """
    test "calculates BP from mixed engineer tiers" do
      builder = Builder.new(%{engineers: %{t1: 2, t2: 1, t3: 1}})

      # 2*2 + 1*5 + 1*15 = 4 + 5 + 15 = 24
      assert builder.total_bp == 24
    end
  end

  describe "start_build/2 - Starting Construction" do
    @doc """
    Test: Starting a build sets up progress tracking.

    Builder records:
    - Target unit
    - Total build time
    - Initial progress: 0
    - Resource costs
    - Status: :building

    Returns consumption rate for Observer.
    """
    test "starts build with correct initial state" do
      builder = Builder.new(%{engineers: %{t1: 5}}) # 10 BP

      {builder, consumption} = Builder.start_build(builder, @t1_engineer)

      assert builder.current_target == @t1_engineer
      assert builder.build_time == 130
      assert builder.progress == 0
      assert builder.status == :building
      # Drain per tick stored in builder: (cost / build_time) * total_bp
      # Mass: (52 / 130) * 10 = 4 per tick
      # Energy: (260 / 130) * 10 = 20 per tick
      assert builder.mass_drain == 4
      assert builder.energy_drain == 20

      # Same drain returned as consumption for Observer
      assert consumption.mass_drain == 4
      assert consumption.energy_drain == 20
    end

    @doc """
    Test: Cannot start build while already building.

    Must complete or cancel current build first.
    """
    test "raises if starting build while busy" do
      builder =
        Builder.new(%{engineers: %{t1: 5}})
        |> Builder.start_build(@t1_engineer)
        |> elem(0)

      assert_raise RuntimeError, fn ->
        Builder.start_build(builder, @t1_engineer)
      end
    end
  end

  describe "tick/2 - Advancing Build" do
    @doc """
    Test: Each tick advances progress by total BP.

    With 10 BP, progress increases by 10 each tick.
    """
    test "advances progress by BP amount each tick" do
      builder =
        Builder.new(%{engineers: %{t1: 5}}) # 10 BP
        |> Builder.start_build(@t1_engineer)
        |> elem(0)

      resources = %{mass_storage: 1000, energy_storage: 5000}

      {builder, status, _drain} = Builder.tick(builder, resources)

      assert builder.progress == 10
      assert status == :continue
    end

    @doc """
    Test: Build completes when progress reaches build_time.

    T1 engineer: build_time = 130
    With 10 BP: completes in 13 ticks (130 / 10 = 13)
    """
    test "completes build when progress reaches build time" do
      builder =
        Builder.new(%{engineers: %{t1: 5}}) # 10 BP
        |> Builder.start_build(@t1_engineer)
        |> elem(0)

      resources = %{mass_storage: 1000, energy_storage: 5000}

      # Progress: 10 per tick, need 130
      # After 13 ticks: 130 progress = complete
      {builder, result, _drain} =
        Enum.reduce(1..13, {builder, :continue, %{}}, fn _, {b, _, _} ->
          Builder.tick(b, resources)
        end)

      assert result == {:completed, @t1_engineer}
      assert builder.status == :idle
      assert builder.current_target == nil
    end

    @doc """
    Test: Build stalls when not enough resources.

    Like in the game, if you run out of mass/energy,
    the build pauses until resources are available.
    """
    test "stalls when resources insufficient" do
      builder =
        Builder.new(%{engineers: %{t1: 5}}) # 10 BP
        |> Builder.start_build(@t1_engineer)
        |> elem(0)

      # Not enough resources (need 4 mass, have 2)
      low_resources = %{mass_storage: 2, energy_storage: 5000}

      {builder, status, _drain} = Builder.tick(builder, low_resources)

      assert status == :stalled
      assert builder.status == :stalled
      # Progress doesn't advance
      assert builder.progress == 0
    end

    @doc """
    Test: Build resumes when resources become available.

    After stalling, if resources arrive, building continues.
    """
    test "resumes when resources available after stall" do
      builder =
        Builder.new(%{engineers: %{t1: 5}})
        |> Builder.start_build(@t1_engineer)
        |> elem(0)

      # Stall first
      low_resources = %{mass_storage: 0, energy_storage: 0}
      {builder, :stalled, _} = Builder.tick(builder, low_resources)

      # Now resources available
      good_resources = %{mass_storage: 1000, energy_storage: 5000}
      {builder, status, _} = Builder.tick(builder, good_resources)

      assert status == :continue
      assert builder.status == :building
      assert builder.progress == 10
    end

    @doc """
    Test: Idle builder returns idle status.

    When not building, tick does nothing.
    """
    test "idle builder stays idle" do
      builder = Builder.new()

      resources = %{mass_storage: 1000, energy_storage: 5000}
      {_builder, status, drain} = Builder.tick(builder, resources)

      assert status == :idle
      assert drain.mass_drain == 0
      assert drain.energy_drain == 0
    end
  end

  describe "progress_percent/1 - Progress Reporting" do
    @doc """
    Test: Progress percentage calculated correctly.

    50% complete when progress is half of build_time.
    """
    test "calculates progress percentage" do
      builder =
        Builder.new(%{engineers: %{t1: 5}}) # 10 BP
        |> Builder.start_build(@t1_engineer)
        |> elem(0)

      # Manually set progress
      builder = %{builder | progress: 65} # Half of 130

      assert Builder.progress_percent(builder) == 50
    end

    @doc """
    Test: 0% progress at start.
    """
    test "returns 0% for new build" do
      builder =
        Builder.new(%{engineers: %{t1: 5}})
        |> Builder.start_build(@t1_engineer)
        |> elem(0)

      assert Builder.progress_percent(builder) == 0
    end
  end

  describe "idle?/1 - Status Check" do
    @doc """
    Test: idle? returns true only when not building.
    """
    test "reports idle status correctly" do
      idle_builder = Builder.new()
      assert Builder.idle?(idle_builder)

      busy_builder =
        Builder.new(%{engineers: %{t1: 5}})
        |> Builder.start_build(@t1_engineer)
        |> elem(0)

      refute Builder.idle?(busy_builder)
    end
  end
end
