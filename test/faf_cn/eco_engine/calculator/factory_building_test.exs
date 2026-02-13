defmodule FafCn.EcoEngine.Calculator.FactoryBuildingTest do
  @moduledoc """
  Tests for R2.3 & R7: Factory building requirements.

  Requirements covered:
  - R2.3: Factory required for battle units
  - R7.1: Factory assumed exists (include_factory: false)
  - R7.2: Build factory first (include_factory: true)
  """
  use ExUnit.Case, async: true

  alias FafCn.EcoEngine.Calculator
  alias FafCn.Units

  describe "R7.1: Battle units with existing factory" do
    @tag :skip
    test "build Percival assuming T3 factory exists" do
      # include_factory: false means factory already exists
      # BP = Factory_BP + Engineers_BP

      initial_eco = %{
        mass_income: 10,
        energy_income: 100,
        mass_storage: 2000,
        mass_storage_max: 2000,
        energy_storage: 10_000,
        energy_storage_max: 10_000,
        # 5 T3 engineers = 75 BP
        engineers: %{t1: 0, t2: 0, t3: 5}
      }

      # Percival
      unit = Units.get_unit_by_unit_id("UEL0303")

      goal = %{
        unit: unit,
        quantity: 1,
        # Factory exists
        include_factory: false
      }

      result = Calculator.run(initial_eco, goal)

      # BP = 90 (T3 factory) + 75 (engineers) = 165 BP
      # Build time: 3600 / 165 = 22 seconds
      assert result.completion_time == 22

      # No factory milestone since we didn't build it
      refute Enum.any?(result.milestones, &(&1.type == :factory_complete))
    end

    @tag :skip
    test "build T1 tank with T1 factory" do
      initial_eco = %{
        mass_income: 10,
        energy_income: 100,
        mass_storage: 500,
        mass_storage_max: 1000,
        energy_storage: 2000,
        energy_storage_max: 2000,
        # 10 BP
        engineers: %{t1: 2, t2: 0, t3: 0}
      }

      # T1 Medium Tank
      unit = Units.get_unit_by_unit_id("UEL0201")

      goal = %{
        unit: unit,
        quantity: 1,
        include_factory: false
      }

      result = Calculator.run(initial_eco, goal)

      # BP = 20 (T1 factory) + 10 (engineers) = 30 BP
      # Build time: 270 / 30 = 9 seconds
      assert result.completion_time == 9
    end
  end

  describe "R7.2: Build factory first then units" do
    @tag :skip
    test "build T3 factory + Percival" do
      # include_factory: true means build factory first

      initial_eco = %{
        mass_income: 100,
        energy_income: 1000,
        mass_storage: 5000,
        mass_storage_max: 5000,
        energy_storage: 20_000,
        energy_storage_max: 20_000,
        # 50 BP
        engineers: %{t1: 10, t2: 0, t3: 0}
      }

      percival = Units.get_unit_by_unit_id("UEL0303")

      goal = %{
        unit: percival,
        quantity: 1,
        # Build T3 Land Factory first
        include_factory: true
      }

      result = Calculator.run(initial_eco, goal)

      # Phase 1: Build T3 Land Factory
      # Cost: 5040M, 39400E, 8200 BT (from unit data)
      # BP: 50 (engineers only)
      # Factory build time: 8200 / 50 = 164 seconds

      # Phase 2: Build Percival
      # BP: 90 (new factory) + 50 (engineers) = 140 BP
      # Percival build time: 3600 / 140 = 26 seconds

      # Total: 164 + 26 = 190 seconds (plus resource accumulation time)
      assert result.completion_time > 190

      # Should have factory milestone
      factory_milestone = Enum.find(result.milestones, &(&1.type == :factory_complete))
      assert factory_milestone != nil
      assert factory_milestone.time > 0

      # Factory should complete before goal
      assert factory_milestone.time < result.completion_time
    end

    @tag :skip
    test "build factory + multiple units" do
      initial_eco = %{
        mass_income: 100,
        energy_income: 1000,
        mass_storage: 10_000,
        mass_storage_max: 10_000,
        energy_storage: 50_000,
        energy_storage_max: 50_000,
        engineers: %{t1: 10, t2: 0, t3: 0}
      }

      # T2 Flak Tank
      unit = Units.get_unit_by_unit_id("UEL0202")

      goal = %{
        unit: unit,
        quantity: 5,
        # Build T2 Land Factory first
        include_factory: true
      }

      result = Calculator.run(initial_eco, goal)

      # Build order should show:
      # 1. T2 Land Factory
      # 2. T2 Flak Tank (×5)
      assert length(result.build_order) == 6

      first_build = hd(result.build_order)
      assert first_build.unit == "Land Factory HQ" or first_build.unit == "Land Factory"
    end
  end

  describe "R2.2: Experimental units never need factory" do
    @tag :skip
    test "build Fatboy - factory ignored even if include_factory: true" do
      initial_eco = %{
        mass_income: 100,
        energy_income: 1000,
        mass_storage: 30_000,
        mass_storage_max: 30_000,
        energy_storage: 400_000,
        energy_storage_max: 400_000,
        # 150 BP
        engineers: %{t1: 0, t2: 0, t3: 10}
      }

      fatboy = Units.get_unit_by_unit_id("UEL0401")

      goal = %{
        unit: fatboy,
        quantity: 1,
        # Should be ignored for experimental
        include_factory: true
      }

      result = Calculator.run(initial_eco, goal)

      # BP: 150 (engineers only, no factory)
      # Build time: 47500 / 150 = 317 seconds
      assert result.completion_time == 317

      # No factory milestone for experimental
      refute Enum.any?(result.milestones, &(&1.type == :factory_complete))
    end
  end
end
