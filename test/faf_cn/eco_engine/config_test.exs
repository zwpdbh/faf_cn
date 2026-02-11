defmodule FafCn.EcoEngine.ConfigTest do
  use ExUnit.Case, async: true

  alias FafCn.EcoEngine.Config

  describe "new/1" do
    test "creates config with defaults" do
      config = Config.new()

      assert config.t1_mex_count == 2
      assert config.t2_mex_count == 0
      assert config.t3_mex_count == 0
      assert config.mass_storage == 650
      assert config.energy_storage == 2500
      assert config.build_order == []
    end

    test "creates config with custom values" do
      config = Config.new(%{
        t1_mex_count: 4,
        t2_mex_count: 2,
        t3_mex_count: 1,
        mass_storage: 1000,
        energy_storage: 5000
      })

      assert config.t1_mex_count == 4
      assert config.t2_mex_count == 2
      assert config.t3_mex_count == 1
      assert config.mass_storage == 1000
      assert config.energy_storage == 5000
    end

    test "handles partial overrides" do
      config = Config.new(%{t1_mex_count: 5})

      assert config.t1_mex_count == 5
      assert config.t2_mex_count == 0  # default
      assert config.mass_storage == 650  # default
    end
  end

  describe "mass_income_per_tick/1" do
    test "calculates T1 mex income correctly" do
      config = Config.new(%{t1_mex_count: 2})
      assert Config.mass_income_per_tick(config) == 4
    end

    test "calculates T2 mex income correctly" do
      config = Config.new(%{t1_mex_count: 0, t2_mex_count: 2, t3_mex_count: 0})
      assert Config.mass_income_per_tick(config) == 12
    end

    test "calculates T3 mex income correctly" do
      config = Config.new(%{t1_mex_count: 0, t2_mex_count: 0, t3_mex_count: 1})
      assert Config.mass_income_per_tick(config) == 18
    end

    test "calculates mixed mex income correctly" do
      config = Config.new(%{
        t1_mex_count: 2,  # 4 mass/sec
        t2_mex_count: 1,  # 6 mass/sec
        t3_mex_count: 1   # 18 mass/sec
      })

      assert Config.mass_income_per_tick(config) == 28
    end

    test "returns 0 with no mex" do
      config = Config.new(%{t1_mex_count: 0, t2_mex_count: 0, t3_mex_count: 0})
      assert Config.mass_income_per_tick(config) == 0
    end

    test "calculates income with default T1 mex" do
      # Default config has 2 T1 mex
      config = Config.new()
      assert Config.mass_income_per_tick(config) == 4
    end
  end
end
