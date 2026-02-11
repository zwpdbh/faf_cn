defmodule FafCn.EcoEngine.SimulatorTest do
  use ExUnit.Case, async: true

  alias FafCn.EcoEngine.{Config, Simulator, State}

  describe "init/1" do
    test "creates initial state" do
      config = Config.new(%{t1_mex_count: 2})
      state = Simulator.init(config)

      assert %State{} = state
      assert state.tick == 0
      assert state.mass_storage == 650
    end
  end

  describe "tick/1" do
    test "advances tick counter" do
      config = Config.new()
      state = Simulator.init(config)
      new_state = Simulator.tick(state)

      assert new_state.tick == 1
    end

    test "adds T1 mex income" do
      # 4 mass/sec
      config = Config.new(%{t1_mex_count: 2})
      state = Simulator.init(config)
      new_state = Simulator.tick(state)

      # 650 + 4
      assert new_state.mass_storage == 654
      assert new_state.mass_income == 4
    end

    test "adds T2 mex income" do
      # 6 mass/sec
      config = Config.new(%{t1_mex_count: 0, t2_mex_count: 1, t3_mex_count: 0})
      state = Simulator.init(config)
      new_state = Simulator.tick(state)

      # 650 + 6
      assert new_state.mass_storage == 656
    end

    test "adds T3 mex income" do
      # 18 mass/sec
      config = Config.new(%{t1_mex_count: 0, t2_mex_count: 0, t3_mex_count: 1})
      state = Simulator.init(config)
      new_state = Simulator.tick(state)

      # 650 + 18
      assert new_state.mass_storage == 668
    end

    test "adds mixed mex income" do
      config =
        Config.new(%{
          # 2 mass/sec
          t1_mex_count: 1,
          # 6 mass/sec
          t2_mex_count: 1,
          # 18 mass/sec
          t3_mex_count: 1
        })

      state = Simulator.init(config)
      new_state = Simulator.tick(state)

      # 650 + 26
      assert new_state.mass_storage == 676
    end

    test "accumulates mass over time" do
      # 2 mass/sec
      config = Config.new(%{t1_mex_count: 1})
      state = Simulator.init(config)

      # Tick 5 times
      new_state =
        Enum.reduce(1..5, state, fn _, acc ->
          Simulator.tick(acc)
        end)

      assert new_state.tick == 5
      # 650 + (2 * 5)
      assert new_state.mass_storage == 660
      assert new_state.accumulated_mass == 660
    end

    test "energy stays constant (simplified model)" do
      config = Config.new()
      state = Simulator.init(config)
      new_state = Simulator.tick(state)

      # unchanged
      assert new_state.energy_storage == 2500
    end
  end

  describe "run/2" do
    test "runs simulation for specified ticks" do
      # 2 mass/sec
      config = Config.new(%{t1_mex_count: 1})
      states = Simulator.run(config, 5)

      # initial + 5 ticks
      assert length(states) == 6

      # Check first state (initial)
      assert hd(states).tick == 0
      assert hd(states).mass_storage == 650

      # Check last state
      last = List.last(states)
      assert last.tick == 5
      # 650 + (2 * 5)
      assert last.mass_storage == 660
    end

    test "returns correct state progression" do
      # 2 mass/sec
      config = Config.new(%{t1_mex_count: 1})
      states = Simulator.run(config, 3)

      masses = Enum.map(states, & &1.mass_storage)
      assert masses == [650, 652, 654, 656]
    end
  end

  describe "run_chart_data/2" do
    test "returns data in chart format" do
      config = Config.new(%{t1_mex_count: 1})
      chart_data = Simulator.run_chart_data(config, 3)

      # initial + 3 ticks
      assert length(chart_data) == 4

      first = hd(chart_data)
      assert first.time == 0
      assert first.mass == 650

      last = List.last(chart_data)
      assert last.time == 3
      assert last.mass == 656
    end
  end
end
