defmodule FafCn.EcoEngine.BuildProgressTest do
  @moduledoc """
  Tests for build progress calculation using Fatboy as target.

  Fatboy (UEL0401) - UEF Experimental Mobile Factory
  - Mass: 28,000
  - Energy: 350,000
  - Build time: 47,500

  Core formula: ticks_needed = target_build_time / build_power (float)
  """
  use ExUnit.Case, async: true

  alias FafCn.EcoEngine.Player

  # Fatboy stats
  @fatboy_mass 28_000
  @fatboy_power 350_000
  @fatboy_time 47_500

  describe "when there are infinite mass and power available" do
    # In this sceanrio, the build speed is totally controlled by build power.
    test "case01: with 150 BP (10 T3 engineers)" do
      player =
        Player.new(%{
          target_mass: @fatboy_mass,
          target_power: @fatboy_power,
          target_build_time: @fatboy_time,
          build_power: 150,
          idle: false
        })

      # Build time as float: 47,500 / 150 = 316.67 ticks
      ticks = @fatboy_time / 150
      assert_in_delta ticks, 316.67, 0.01

      # Drain per second (float values)
      mass_drain = Player.mass_drain_per_sec(player)
      energy_drain = Player.energy_drain_per_sec(player)

      # (28,000 / 47,500) * 150 = 88.421...
      assert_in_delta mass_drain, 88.42, 0.01
      # (350,000 / 47,500) * 150 = 1,105.26...
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

      # Build time: 47,500 / 300 = 158.33 ticks
      ticks = @fatboy_time / 300
      assert_in_delta ticks, 158.33, 0.01

      # Drain per second (2x the 150 BP rate)
      mass_drain = Player.mass_drain_per_sec(player)
      energy_drain = Player.energy_drain_per_sec(player)

      # 2 * 88.42
      assert_in_delta mass_drain, 176.84, 0.01
      # 2 * 1,105.26
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
    # Formula: actual_bp = min(available_bp, mass_produce / mass_drain_per_bp, energy_produce / energy_drain_per_bp)
    # where mass_drain_per_bp = mass_cost / build_time

    test "case01: 10 T3 engineers (150 BP), 40 mass/sec, 1200 energy/sec" do
      # With 150 BP, theoretical drain:
      # - Mass: (28000/47500) * 150 = 88.42 mass/sec
      # - Energy: (350000/47500) * 150 = 1105.26 energy/sec
      #
      # But we only have 40 mass/sec! So mass is the bottleneck.
      # Actual BP = 40 / (28000/47500) = 40 * 47500 / 28000 = 67.86 BP

      mass_produce = 40
      energy_produce = 1200
      available_bp = 150

      # Calculate actual BP based on mass constraint
      mass_drain_per_bp = @fatboy_mass / @fatboy_time
      actual_bp_by_mass = mass_produce / mass_drain_per_bp

      # Calculate actual BP based on energy constraint
      energy_drain_per_bp = @fatboy_power / @fatboy_time
      actual_bp_by_energy = energy_produce / energy_drain_per_bp

      # Actual BP is the minimum of all constraints
      actual_bp = min(available_bp, min(actual_bp_by_mass, actual_bp_by_energy))

      # Mass is the limiting factor
      assert_in_delta actual_bp_by_mass, 67.86, 0.01
      assert actual_bp_by_energy > actual_bp_by_mass  # Energy is not limiting
      assert_in_delta actual_bp, 67.86, 0.01

      # Build time with constrained BP
      ticks = @fatboy_time / actual_bp
      assert_in_delta ticks, 700.0, 0.1

      # Verify resource consumption equals production (net zero with 0 storage)
      actual_mass_drain = mass_drain_per_bp * actual_bp
      actual_energy_drain = energy_drain_per_bp * actual_bp

      assert_in_delta actual_mass_drain, mass_produce, 0.01
      assert actual_energy_drain < energy_produce  # Energy has surplus
    end

    test "case02: 20 T3 engineers (300 BP), 40 mass/sec, 1200 energy/sec" do
      # Even with 300 BP available, mass is still the bottleneck at 40/sec
      mass_produce = 40
      energy_produce = 1200
      available_bp = 300

      mass_drain_per_bp = @fatboy_mass / @fatboy_time
      actual_bp_by_mass = mass_produce / mass_drain_per_bp

      energy_drain_per_bp = @fatboy_power / @fatboy_time
      actual_bp_by_energy = energy_produce / energy_drain_per_bp

      actual_bp = min(available_bp, min(actual_bp_by_mass, actual_bp_by_energy))

      # Same as case01 - mass limited
      assert_in_delta actual_bp, 67.86, 0.01

      # Build time same as case01
      ticks = @fatboy_time / actual_bp
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

      mass_drain_per_bp = @fatboy_mass / @fatboy_time
      actual_bp_by_mass = mass_produce / mass_drain_per_bp

      energy_drain_per_bp = @fatboy_power / @fatboy_time
      actual_bp_by_energy = energy_produce / energy_drain_per_bp

      # Energy limit: 800 / (350000/47500) = 800 * 47500 / 350000 = 108.57 BP
      assert_in_delta actual_bp_by_energy, 108.57, 0.01
      assert actual_bp_by_mass > actual_bp_by_energy  # Mass is not limiting

      actual_bp = min(available_bp, min(actual_bp_by_mass, actual_bp_by_energy))
      assert_in_delta actual_bp, 108.57, 0.01

      # Build time with energy constraint
      ticks = @fatboy_time / actual_bp
      assert_in_delta ticks, 437.5, 0.1

      actual_energy_drain = energy_drain_per_bp * actual_bp
      assert_in_delta actual_energy_drain, energy_produce, 0.01
    end
  end
end
