defmodule FafCn.EcoEngine.Calculator.SimpleBuildsTest do
  @moduledoc """
  Tests for R1 & R2: Simple build scenarios with sufficient resources.

  Requirements covered:
  - R1.1: Calculate optimal build order
  - R2.1: Goal definition (unit, quantity, include_factory)
  - R2.2: Experimental units don't need factory
  """
  use ExUnit.Case, async: true

  alias FafCn.EcoEngine.Calculator
  alias FafCn.Units

  describe "R2.2: Experimental units - no factory needed" do
    @tag :skip
    test "build Galactic Colossus with sufficient resources" do
      # Goal: Build 1 Galactic Colossus (27500M, 343000E, 12500 BT)
      # Initial: Plenty of resources, 10 T3 engineers (150 BP)

      initial_eco = %{
        mass_income: 10,
        energy_income: 100,
        mass_storage: 30_000,
        mass_storage_max: 30_000,
        energy_storage: 350_000,
        energy_storage_max: 350_000,
        engineers: %{t1: 0, t2: 0, t3: 10}
      }

      # Galactic Colossus
      unit = Units.get_unit_by_unit_id("UAL0401")

      goal = %{
        unit: unit,
        quantity: 1,
        # Experiments don't need factory
        include_factory: false
      }

      result = Calculator.run(initial_eco, goal)

      # Build time: 12500 / 150 = 83.3 -> 84 seconds
      # Already have enough mass and energy
      assert result.completion_time == 84

      # Verify milestones
      assert Enum.any?(result.milestones, &(&1.type == :start))
      assert Enum.any?(result.milestones, &(&1.type == :goal_complete))

      # No factory milestone for experimental
      refute Enum.any?(result.milestones, &(&1.type == :factory_complete))
    end
  end

  describe "R1.1: Simple build - limited by build time" do
    @tag :skip
    test "build T1 engineer with sufficient resources" do
      # Goal: Build 1 T1 Engineer (52M, 260E, 130 BT)
      # Initial: 650M, 2500E storage, 10M/s, 100E/s income
      # 5 T1 engineers = 25 BP

      initial_eco = %{
        mass_income: 10,
        energy_income: 100,
        mass_storage: 650,
        mass_storage_max: 650,
        energy_storage: 2500,
        energy_storage_max: 2500,
        engineers: %{t1: 5, t2: 0, t3: 0}
      }

      unit = Units.get_unit_by_unit_id("UEL0105")

      goal = %{
        unit: unit,
        quantity: 1,
        include_factory: false
      }

      result = Calculator.run(initial_eco, goal)

      # Build time: 130 / 25 = 5.2 -> 6 seconds
      # Mass time: max(0, 52 - 650) / 10 = 0
      # Energy time: max(0, 260 - 2500) / 100 = 0
      assert result.completion_time == 6
    end

    @tag :skip
    test "build multiple units - sequential" do
      # Goal: Build 5 T1 Engineers
      # Sequential building means 5x the time

      initial_eco = %{
        mass_income: 10,
        energy_income: 100,
        mass_storage: 1000,
        mass_storage_max: 1000,
        energy_storage: 5000,
        energy_storage_max: 5000,
        engineers: %{t1: 5, t2: 0, t3: 0}
      }

      unit = Units.get_unit_by_unit_id("UEL0105")

      goal = %{
        unit: unit,
        quantity: 5,
        include_factory: false
      }

      result = Calculator.run(initial_eco, goal)

      # 5 units × 6 seconds each = 30 seconds (sequential)
      assert result.completion_time == 30

      # Should have 5 build entries in build_order
      assert length(result.build_order) == 5
    end
  end

  describe "R2.1: Goal definition validation" do
    @tag :skip
    test "validates unit exists" do
      initial_eco = %{
        mass_income: 10,
        energy_income: 100,
        mass_storage: 1000,
        mass_storage_max: 1000,
        energy_storage: 5000,
        energy_storage_max: 5000,
        engineers: %{t1: 5, t2: 0, t3: 0}
      }

      goal = %{
        unit: nil,
        quantity: 1,
        include_factory: false
      }

      # Should return error for invalid unit
      assert {:error, _} = Calculator.run(initial_eco, goal)
    end

    @tag :skip
    test "validates quantity is positive" do
      initial_eco = %{
        mass_income: 10,
        energy_income: 100,
        mass_storage: 1000,
        mass_storage_max: 1000,
        energy_storage: 5000,
        energy_storage_max: 5000,
        engineers: %{t1: 5, t2: 0, t3: 0}
      }

      unit = Units.get_unit_by_unit_id("UEL0105")

      goal = %{
        unit: unit,
        quantity: 0,
        include_factory: false
      }

      # Should return error for zero quantity
      assert {:error, _} = Calculator.run(initial_eco, goal)
    end
  end
end
