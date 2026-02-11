defmodule FafCn.EcoEngine.StateTest do
  use ExUnit.Case, async: true

  alias FafCn.EcoEngine.{Config, State}

  describe "initial/1" do
    test "creates initial state from config" do
      config =
        Config.new(%{
          t1_mex_count: 3,
          mass_storage: 500,
          energy_storage: 2000
        })

      state = State.initial(config)

      assert state.tick == 0
      assert state.mass_storage == 500
      assert state.energy_storage == 2000
      assert state.mass_income == 0
      assert state.energy_income == 0
      # ACU default
      assert state.build_power == 10
      assert state.accumulated_mass == 500
      assert state.config == config
    end
  end

  describe "to_chart_data/1" do
    test "converts state to chart format" do
      config = Config.new()

      state = %State{
        tick: 100,
        mass_storage: 750.5,
        energy_storage: 2400.3,
        mass_income: 4,
        energy_income: 0,
        build_power: 15,
        accumulated_mass: 800.2,
        config: config
      }

      chart_data = State.to_chart_data(state)

      assert chart_data.time == 100
      # rounded
      assert chart_data.mass == 751
      # rounded
      assert chart_data.energy == 2400
      assert chart_data.build_power == 15
      # rounded
      assert chart_data.accumulated_mass == 800
    end
  end
end
