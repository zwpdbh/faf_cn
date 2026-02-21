defmodule FafCn.EcoEngine.BuildScenarioTest do
  @moduledoc """
  Integration tests for BuildPower with Player module.

  These tests verify BuildPower calculations work correctly when
  integrated with the Player module's drain rate calculations.

  Fatboy (UEL0401) stats:
  - Mass: 28,000
  - Energy: 350,000
  - Build time: 47,500
  """
  use ExUnit.Case, async: true

  alias FafCn.EcoEngine.Player
  alias FafCn.EcoEngine.BuildPower

  @fatboy_mass 28_000.0
  @fatboy_power 350_000.0
  @fatboy_time 47_500.0

  describe "Player drain rates match BuildPower calculations" do
    test "mass and energy drain at 150 BP" do
      player =
        Player.new(%{
          target_mass: @fatboy_mass,
          target_power: @fatboy_power,
          target_build_time: @fatboy_time,
          build_power: 150,
          idle: false
        })

      # Player drain should match BuildPower calculation
      mass_drain_per_bp = BuildPower.drain_per_bp(@fatboy_mass, @fatboy_time)
      energy_drain_per_bp = BuildPower.drain_per_bp(@fatboy_power, @fatboy_time)

      assert_in_delta Player.mass_drain_per_sec(player), mass_drain_per_bp * 150, 0.01
      assert_in_delta Player.energy_drain_per_sec(player), energy_drain_per_bp * 150, 0.01
    end

    test "mass and energy drain at 300 BP" do
      player =
        Player.new(%{
          target_mass: @fatboy_mass,
          target_power: @fatboy_power,
          target_build_time: @fatboy_time,
          build_power: 300,
          idle: false
        })

      mass_drain_per_bp = BuildPower.drain_per_bp(@fatboy_mass, @fatboy_time)
      energy_drain_per_bp = BuildPower.drain_per_bp(@fatboy_power, @fatboy_time)

      assert_in_delta Player.mass_drain_per_sec(player), mass_drain_per_bp * 300, 0.01
      assert_in_delta Player.energy_drain_per_sec(player), energy_drain_per_bp * 300, 0.01
    end

    test "idle player has zero drain" do
      player =
        Player.new(%{
          target_mass: @fatboy_mass,
          target_power: @fatboy_power,
          target_build_time: @fatboy_time,
          build_power: 150,
          idle: true
        })

      assert Player.mass_drain_per_sec(player) == 0
      assert Player.energy_drain_per_sec(player) == 0
    end
  end

  describe "End-to-end build scenarios" do
    test "mass-limited build with 40 mass/sec production" do
      # Setup: 150 BP available but only 40 mass/sec
      available_bp = 150
      mass_produce = 40
      energy_produce = 1200

      # Calculate actual BP using BuildPower
      mass_drain_per_bp = BuildPower.drain_per_bp(@fatboy_mass, @fatboy_time)
      bp_limited_by_mass = BuildPower.bp_limited_by_resource(mass_produce, mass_drain_per_bp)
      energy_drain_per_bp = BuildPower.drain_per_bp(@fatboy_power, @fatboy_time)

      bp_limited_by_energy =
        BuildPower.bp_limited_by_resource(energy_produce, energy_drain_per_bp)

      actual_bp = BuildPower.actual_bp(available_bp, bp_limited_by_mass, bp_limited_by_energy)

      # Verify mass is the limiting factor
      assert_in_delta actual_bp, 67.86, 0.1

      # Calculate build time
      ticks = BuildPower.ticks_needed(@fatboy_time, actual_bp)
      assert_in_delta ticks, 700, 1

      # Verify total mass consumed equals Fatboy mass cost
      mass_drain_at_actual_bp = mass_drain_per_bp * actual_bp
      total_mass_consumed = mass_drain_at_actual_bp * ticks
      assert_in_delta total_mass_consumed, @fatboy_mass, 1
    end

    test "two-phase build with 14k mass storage" do
      # Scenario: Start with storage buffer, then hit mass limit
      result =
        BuildPower.two_phase_build_time(
          @fatboy_time,
          # available BP
          150,
          # mass/sec
          40,
          # energy/sec
          1200,
          # mass storage
          14_000,
          # energy storage
          175_000
        )

      # Should complete faster than 0-storage case (700 ticks) but slower than infinite (317 ticks)
      assert_in_delta result, 350, 1

      # Verify with metrics
      metrics =
        BuildPower.calculate_metrics(
          %{mass: @fatboy_mass, energy: @fatboy_power, build_time: @fatboy_time},
          150,
          %{mass: 40, energy: 1200},
          %{mass: 14_000, energy: 175_000}
        )

      assert metrics.phase1.depletes == :mass
      assert_in_delta metrics.total_ticks, 350, 1
    end

    test "energy-limited build completes before storage depletion" do
      # Scenario: Energy would be limiting but we have enough storage
      result =
        BuildPower.two_phase_build_time(
          @fatboy_time,
          # available BP
          150,
          # mass/sec (plenty)
          100,
          # energy/sec (limiting)
          800,
          # mass storage
          14_000,
          # energy storage (enough buffer)
          175_000
        )

      # Build completes at full BP before energy runs out
      assert_in_delta result, 316.67, 0.5
    end
  end
end
