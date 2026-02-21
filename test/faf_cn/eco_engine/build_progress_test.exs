defmodule FafCn.EcoEngine.BuildProgressTest do
  @moduledoc """
  Integration tests for build progress calculation using Fatboy as target.

  These tests verify the BuildPower module produces correct results
  in real-world scenarios using Fatboy stats.

  Fatboy (UEL0401) - UEF Experimental Mobile Factory
  - Mass: 28,000
  - Energy: 350,000
  - Build time: 47,500

  Core formula: ticks_needed = target_build_time / build_power (float)
  """
  use ExUnit.Case, async: true

  alias FafCn.EcoEngine.Player
  alias FafCn.EcoEngine.BuildPower

  # Fatboy stats
  @fatboy_mass 28_000.0
  @fatboy_power 350_000.0
  @fatboy_time 47_500.0

  describe "when there are infinite mass and power available" do
    # In this scenario, the build speed is totally controlled by build power.
    test "case01: with 150 BP (10 T3 engineers)" do
      player =
        Player.new(%{
          target_mass: @fatboy_mass,
          target_power: @fatboy_power,
          target_build_time: @fatboy_time,
          build_power: 150,
          idle: false
        })

      # Build time using BuildPower module
      ticks = BuildPower.ticks_needed(@fatboy_time, 150)
      assert_in_delta ticks, 316.67, 0.01

      # Drain per second (float values)
      mass_drain = Player.mass_drain_per_sec(player)
      energy_drain = Player.energy_drain_per_sec(player)

      # Verify using BuildPower drain calculation
      mass_drain_per_bp = BuildPower.drain_per_bp(@fatboy_mass, @fatboy_time)
      assert_in_delta mass_drain, mass_drain_per_bp * 150, 0.01
      assert_in_delta mass_drain, 88.42, 0.01

      energy_drain_per_bp = BuildPower.drain_per_bp(@fatboy_power, @fatboy_time)
      assert_in_delta energy_drain, energy_drain_per_bp * 150, 0.01
      assert_in_delta energy_drain, 1_105.26, 0.01

      # Total consumption should match unit cost
      assert_in_delta mass_drain * ticks, @fatboy_mass, 0.1
      assert_in_delta energy_drain * ticks, @fatboy_power, 0.1
    end

    test "with 300 BP (20 T3 engineers)" do
      player =
        Player.new(%{
          target_mass: @fatboy_mass,
          target_power: @fatboy_power,
          target_build_time: @fatboy_time,
          build_power: 300,
          idle: false
        })

      # Build time using BuildPower module
      ticks = BuildPower.ticks_needed(@fatboy_time, 300)
      assert_in_delta ticks, 158.33, 0.01

      # Drain per second (2x the 150 BP rate)
      mass_drain = Player.mass_drain_per_sec(player)
      energy_drain = Player.energy_drain_per_sec(player)

      # Verify using BuildPower drain calculation
      mass_drain_per_bp = BuildPower.drain_per_bp(@fatboy_mass, @fatboy_time)
      assert_in_delta mass_drain, mass_drain_per_bp * 300, 0.01
      assert_in_delta mass_drain, 176.84, 0.01

      energy_drain_per_bp = BuildPower.drain_per_bp(@fatboy_power, @fatboy_time)
      assert_in_delta energy_drain, energy_drain_per_bp * 300, 0.01
      assert_in_delta energy_drain, 2_210.53, 0.01

      # Total consumption matches unit cost
      assert_in_delta mass_drain * ticks, @fatboy_mass, 0.1
      assert_in_delta energy_drain * ticks, @fatboy_power, 0.1
    end
  end

  describe "test limited resource with 0 mass_storage and 0 energy_storage" do
    # In this case, the build speed is controlled by actual build power.
    # The actual build power is limited by whichever resource hits its production cap first.
    #
    # Uses BuildPower.actual_bp/3 to calculate effective BP

    test "case01: 10 T3 engineers (150 BP), 40 mass/sec, 1200 energy/sec" do
      mass_produce = 40
      energy_produce = 1200
      available_bp = 150

      # Use BuildPower module for calculations
      mass_drain_per_bp = BuildPower.drain_per_bp(@fatboy_mass, @fatboy_time)
      bp_limited_by_mass = BuildPower.bp_limited_by_resource(mass_produce, mass_drain_per_bp)

      energy_drain_per_bp = BuildPower.drain_per_bp(@fatboy_power, @fatboy_time)

      bp_limited_by_energy =
        BuildPower.bp_limited_by_resource(energy_produce, energy_drain_per_bp)

      actual_bp = BuildPower.actual_bp(available_bp, bp_limited_by_mass, bp_limited_by_energy)

      # Mass is the limiting factor
      assert_in_delta bp_limited_by_mass, 67.86, 0.01
      assert bp_limited_by_energy > bp_limited_by_mass
      assert_in_delta actual_bp, 67.86, 0.01

      # Build time using BuildPower
      ticks = BuildPower.ticks_needed(@fatboy_time, actual_bp)
      assert_in_delta ticks, 700.0, 0.1

      # Verify resource consumption equals production (net zero with 0 storage)
      actual_mass_drain = mass_drain_per_bp * actual_bp
      actual_energy_drain = energy_drain_per_bp * actual_bp

      assert_in_delta actual_mass_drain, mass_produce, 0.01
      assert actual_energy_drain < energy_produce
    end

    test "case02: 20 T3 engineers (300 BP), 40 mass/sec, 1200 energy/sec" do
      # Even with 300 BP available, mass is still the bottleneck at 40/sec
      mass_produce = 40
      energy_produce = 1200
      available_bp = 300

      mass_drain_per_bp = BuildPower.drain_per_bp(@fatboy_mass, @fatboy_time)
      bp_limited_by_mass = BuildPower.bp_limited_by_resource(mass_produce, mass_drain_per_bp)

      energy_drain_per_bp = BuildPower.drain_per_bp(@fatboy_power, @fatboy_time)

      bp_limited_by_energy =
        BuildPower.bp_limited_by_resource(energy_produce, energy_drain_per_bp)

      actual_bp = BuildPower.actual_bp(available_bp, bp_limited_by_mass, bp_limited_by_energy)

      # Same as case01 - mass limited
      assert_in_delta actual_bp, 67.86, 0.01

      # Build time same as case01
      ticks = BuildPower.ticks_needed(@fatboy_time, actual_bp)
      assert_in_delta ticks, 700.0, 0.1

      # Adding more engineers doesn't help when mass is the bottleneck
      actual_mass_drain = mass_drain_per_bp * actual_bp
      assert_in_delta actual_mass_drain, mass_produce, 0.01
    end

    test "case03: 10 T3 engineers (150 BP), 100 mass/sec, 800 energy/sec" do
      # Now energy becomes the bottleneck!
      mass_produce = 100
      energy_produce = 800
      available_bp = 150

      mass_drain_per_bp = BuildPower.drain_per_bp(@fatboy_mass, @fatboy_time)
      bp_limited_by_mass = BuildPower.bp_limited_by_resource(mass_produce, mass_drain_per_bp)

      energy_drain_per_bp = BuildPower.drain_per_bp(@fatboy_power, @fatboy_time)

      bp_limited_by_energy =
        BuildPower.bp_limited_by_resource(energy_produce, energy_drain_per_bp)

      # Energy limit: 800 / (350000/47500) = 108.57 BP
      assert_in_delta bp_limited_by_energy, 108.57, 0.01
      assert bp_limited_by_mass > bp_limited_by_energy

      actual_bp = BuildPower.actual_bp(available_bp, bp_limited_by_mass, bp_limited_by_energy)
      assert_in_delta actual_bp, 108.57, 0.01

      # Build time with energy constraint
      ticks = BuildPower.ticks_needed(@fatboy_time, actual_bp)
      assert_in_delta ticks, 437.5, 0.1

      actual_energy_drain = energy_drain_per_bp * actual_bp
      assert_in_delta actual_energy_drain, energy_produce, 0.01
    end
  end

  describe "test limited resource with extra mass in mass_storage and energy_storage" do
    # Half of Fatboy cost as initial storage
    # Mass: 28,000 / 2 = 14,000
    # Energy: 350,000 / 2 = 175,000
    #
    # With storage, build starts at full BP, then drops to income-limited BP
    # when storage depletes.
    # Uses BuildPower.two_phase_build_time/6 for complete calculation

    test "case01: 150 BP, 40 mass/sec, 1200 energy/sec, with 14k mass / 175k energy storage" do
      # Same as 0-storage case01 but with half resources in storage
      mass_produce = 40
      energy_produce = 1200
      available_bp = 150
      initial_mass_storage = 14_000
      initial_energy_storage = 175_000

      # Use two_phase_build_time for complete calculation
      total_ticks =
        BuildPower.two_phase_build_time(
          @fatboy_time,
          available_bp,
          mass_produce,
          energy_produce,
          initial_mass_storage,
          initial_energy_storage
        )

      # With storage boost, build is faster than 0-storage case (700 ticks)
      assert_in_delta total_ticks, 350.0, 1.0

      # Verify phase breakdown using individual functions
      mass_drain_per_bp = BuildPower.drain_per_bp(@fatboy_mass, @fatboy_time)
      full_mass_drain = mass_drain_per_bp * available_bp

      mass_depletion_time =
        BuildPower.storage_depletion_time(initial_mass_storage, full_mass_drain, mass_produce)

      assert_in_delta mass_depletion_time, 289.14, 1.0

      phase1_progress = BuildPower.phase1_progress(available_bp, mass_depletion_time)
      assert_in_delta phase1_progress, 43_365.0, 100.0

      remaining = BuildPower.remaining_progress(@fatboy_time, phase1_progress)
      assert_in_delta remaining, 4_135.0, 100.0
    end

    test "case02: 300 BP, 40 mass/sec, 1200 energy/sec, with 14k mass / 175k energy storage" do
      # More BP depletes storage faster, but same total time due to mass bottleneck
      mass_produce = 40
      energy_produce = 1200
      available_bp = 300
      initial_mass_storage = 14_000
      initial_energy_storage = 175_000

      total_ticks =
        BuildPower.two_phase_build_time(
          @fatboy_time,
          available_bp,
          mass_produce,
          energy_produce,
          initial_mass_storage,
          initial_energy_storage
        )

      # Same total time as case01 - storage determines early phase, income determines late phase
      assert_in_delta total_ticks, 350.0, 1.0

      # Verify faster depletion with more BP
      mass_drain_per_bp = BuildPower.drain_per_bp(@fatboy_mass, @fatboy_time)
      full_mass_drain = mass_drain_per_bp * available_bp

      mass_depletion_time =
        BuildPower.storage_depletion_time(initial_mass_storage, full_mass_drain, mass_produce)

      # ~102 ticks with 300 BP vs ~289 ticks with 150 BP
      assert_in_delta mass_depletion_time, 102.3, 1.0
    end

    test "case03: 150 BP, 100 mass/sec, 800 energy/sec, with 14k mass / 175k energy storage" do
      # Energy is the bottleneck, storage helps initially
      mass_produce = 100
      energy_produce = 800
      available_bp = 150
      initial_mass_storage = 14_000
      initial_energy_storage = 175_000

      total_ticks =
        BuildPower.two_phase_build_time(
          @fatboy_time,
          available_bp,
          mass_produce,
          energy_produce,
          initial_mass_storage,
          initial_energy_storage
        )

      # With full BP and storage buffer, completes in theoretical time
      assert_in_delta total_ticks, 316.67, 0.1

      # Verify energy depletion time
      energy_drain_per_bp = BuildPower.drain_per_bp(@fatboy_power, @fatboy_time)
      full_energy_drain = energy_drain_per_bp * available_bp

      energy_depletion_time =
        BuildPower.storage_depletion_time(
          initial_energy_storage,
          full_energy_drain,
          energy_produce
        )

      # Energy would deplete at ~573 ticks, but build finishes at ~317 ticks
      assert_in_delta energy_depletion_time, 573.3, 1.0
      assert energy_depletion_time > total_ticks
    end
  end
end
