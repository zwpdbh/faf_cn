defmodule FafCn.EcoEngine.BuildPowerTest do
  @moduledoc """
  Tests for the BuildPower calculation module.

  Uses Fatboy (UEL0401) as the primary test unit:
  - Mass: 28,000
  - Energy: 350,000
  - Build time: 47,500
  """
  use ExUnit.Case, async: true

  alias FafCn.EcoEngine.BuildPower

  # Fatboy stats
  @fatboy_mass 28_000.0
  @fatboy_energy 350_000.0
  @fatboy_time 47_500.0

  describe "drain_per_bp/2" do
    test "calculates mass drain per BP for Fatboy" do
      result = BuildPower.drain_per_bp(@fatboy_mass, @fatboy_time)
      # 28000 / 47500 = 0.58947...
      assert_in_delta result, 0.58947, 0.00001
    end

    test "calculates energy drain per BP for Fatboy" do
      result = BuildPower.drain_per_bp(@fatboy_energy, @fatboy_time)
      # 350000 / 47500 = 7.36842...
      assert_in_delta result, 7.36842, 0.00001
    end
  end

  describe "bp_limited_by_resource/2" do
    test "calculates BP limit for 40 mass/sec" do
      mass_drain_per_bp = BuildPower.drain_per_bp(@fatboy_mass, @fatboy_time)
      result = BuildPower.bp_limited_by_resource(40, mass_drain_per_bp)
      # 40 / 0.58947 = 67.86
      assert_in_delta result, 67.86, 0.01
    end

    test "calculates BP limit for 1200 energy/sec" do
      energy_drain_per_bp = BuildPower.drain_per_bp(@fatboy_energy, @fatboy_time)
      result = BuildPower.bp_limited_by_resource(1200, energy_drain_per_bp)
      # 1200 / 7.36842 = 162.86
      assert_in_delta result, 162.86, 0.01
    end
  end

  describe "actual_bp/3" do
    test "returns BP limited by mass when mass is bottleneck" do
      # 150 available, 67.86 mass-limited, 162.86 energy-limited
      result = BuildPower.actual_bp(150, 67.86, 162.86)
      assert_in_delta result, 67.86, 0.01
    end

    test "returns BP limited by energy when energy is bottleneck" do
      # 150 available, 200 mass-limited, 108.57 energy-limited
      result = BuildPower.actual_bp(150, 200, 108.57)
      assert_in_delta result, 108.57, 0.01
    end

    test "returns available BP when not resource constrained" do
      # 150 available, 200 mass-limited, 300 energy-limited
      result = BuildPower.actual_bp(150, 200, 300)
      assert_in_delta result, 150, 0.01
    end
  end

  describe "ticks_needed/2" do
    test "calculates ticks for Fatboy with 150 BP" do
      result = BuildPower.ticks_needed(@fatboy_time, 150)
      # 47500 / 150 = 316.67
      assert_in_delta result, 316.67, 0.01
    end

    test "calculates ticks for Fatboy with 67.86 BP (mass-limited)" do
      result = BuildPower.ticks_needed(@fatboy_time, 67.86)
      # 47500 / 67.86 = 700
      assert_in_delta result, 700, 0.1
    end
  end

  describe "storage_depletion_time/3" do
    test "calculates mass depletion time" do
      # 14000 storage, 88.42 drain, 40 production → 48.42 net drain
      # 14000 / 48.42 = 289.14
      result = BuildPower.storage_depletion_time(14_000, 88.42, 40)
      assert_in_delta result, 289.14, 0.1
    end

    test "returns :infinity when production exceeds drain" do
      # 175000 storage, 1105.26 drain, 1200 production → net gain
      result = BuildPower.storage_depletion_time(175_000, 1105.26, 1200)
      assert result == :infinity
    end

    test "returns :infinity when drain equals production" do
      result = BuildPower.storage_depletion_time(14_000, 100, 100)
      assert result == :infinity
    end
  end

  describe "phase1_progress/2" do
    test "calculates progress during storage phase" do
      # 150 BP * 289.14 ticks = 43,371
      result = BuildPower.phase1_progress(150, 289.14)
      assert_in_delta result, 43_371, 1
    end
  end

  describe "remaining_progress/2" do
    test "calculates remaining build time after phase 1" do
      # 47500 - 43365 = 4135
      result = BuildPower.remaining_progress(@fatboy_time, 43_365)
      assert_in_delta result, 4_135, 1
    end
  end

  describe "phase2_ticks/2" do
    test "calculates phase 2 time with mass-limited BP" do
      # 4135 remaining / 67.86 BP = 60.93
      result = BuildPower.phase2_ticks(4_135, 67.86)
      assert_in_delta result, 60.93, 0.1
    end
  end

  describe "two_phase_build_time/6" do
    test "mass-limited scenario with 14k storage" do
      # 150 BP, 40 mass/sec, 1200 energy/sec, 14k mass, 175k energy
      result =
        BuildPower.two_phase_build_time(
          @fatboy_time,
          150,
          40,
          1200,
          14_000,
          175_000
        )

      # Phase 1: 289.14 ticks at 150 BP
      # Phase 2: 60.93 ticks at 67.86 BP
      # Total: ~350 ticks
      assert_in_delta result, 350, 1
    end

    test "energy-limited scenario where build completes before depletion" do
      # 150 BP, 100 mass/sec, 800 energy/sec, 14k mass, 175k energy
      result =
        BuildPower.two_phase_build_time(
          @fatboy_time,
          150,
          100,
          800,
          14_000,
          175_000
        )

      # Build completes at full BP before energy depletes
      assert_in_delta result, 316.67, 0.1
    end

    test "no storage depletion (production exceeds drain for both)" do
      # High production rates
      result =
        BuildPower.two_phase_build_time(
          @fatboy_time,
          150,
          100,
          2000,
          0,
          0
        )

      # Build at full BP the whole time
      assert_in_delta result, 316.67, 0.1
    end
  end

  describe "calculate_metrics/4" do
    test "returns complete metrics for mass-limited scenario" do
      unit_stats = %{mass: @fatboy_mass, energy: @fatboy_energy, build_time: @fatboy_time}
      production = %{mass: 40, energy: 1200}
      storage = %{mass: 14_000, energy: 175_000}

      metrics = BuildPower.calculate_metrics(unit_stats, 150, production, storage)

      # Verify drain per BP
      assert_in_delta metrics.drain_per_bp.mass, 0.589, 0.001
      assert_in_delta metrics.drain_per_bp.energy, 7.368, 0.001

      # Verify BP limits
      assert_in_delta metrics.bp_limited_by.mass, 67.86, 0.1
      assert_in_delta metrics.bp_limited_by.energy, 162.86, 0.1

      # Verify actual BP
      assert_in_delta metrics.actual_bp, 67.86, 0.1

      # Verify phases
      assert metrics.phase1.depletes == :mass
      assert_in_delta metrics.phase1.time, 289.14, 1
      assert metrics.phase1.progress > 40_000

      assert_in_delta metrics.phase2.bp, 67.86, 0.1
      assert metrics.phase2.time > 50

      # Verify total
      assert_in_delta metrics.total_ticks, 350, 1
    end

    test "returns complete metrics for energy-limited scenario" do
      unit_stats = %{mass: @fatboy_mass, energy: @fatboy_energy, build_time: @fatboy_time}
      production = %{mass: 100, energy: 800}
      storage = %{mass: 14_000, energy: 175_000}

      metrics = BuildPower.calculate_metrics(unit_stats, 150, production, storage)

      # Energy is limiting (with 0 storage)
      assert_in_delta metrics.actual_bp, 108.57, 0.1

      # But with storage, build completes before energy depletes
      # Depletion time: 573.3 ticks, Build at full BP: 316.67 ticks
      assert metrics.phase1.depletes == :energy
      assert_in_delta metrics.total_ticks, 316.67, 0.1
    end

    test "returns complete metrics when storage never depletes" do
      unit_stats = %{mass: @fatboy_mass, energy: @fatboy_energy, build_time: @fatboy_time}
      production = %{mass: 100, energy: 2000}
      storage = %{mass: 14_000, energy: 175_000}

      metrics = BuildPower.calculate_metrics(unit_stats, 150, production, storage)

      # No depletion
      assert metrics.phase1.depletes == :none
      assert metrics.phase1.time == :infinity
      assert_in_delta metrics.total_ticks, 316.67, 0.1
    end
  end
end
