defmodule FafCn.EcoEngine.GameTest do
  @moduledoc """
  Tests for Game - world state.
  """
  use ExUnit.Case, async: true

  alias FafCn.EcoEngine.Game

  describe "new/1 - Initialization" do
    test "creates with defaults" do
      game = Game.new()

      assert game.mass_storage == 0
      assert game.energy_storage == 0
      assert game.mass_produce_per_sec == 0
      assert game.energy_produce_per_sec == 0
      assert game.mass_drain_per_sec == 0
      assert game.energy_drain_per_sec == 0
    end

    test "accepts custom values" do
      game = Game.new(%{
        mass_storage: 650,
        energy_storage: 2500,
        mass_produce_per_sec: 10,
        energy_produce_per_sec: 100
      })

      assert game.mass_storage == 650
      assert game.energy_storage == 2500
      assert game.mass_produce_per_sec == 10
      assert game.energy_produce_per_sec == 100
    end
  end

  describe "set_drain/3" do
    test "sets drain rates" do
      game = Game.new()
      game = Game.set_drain(game, 4, 20)

      assert game.mass_drain_per_sec == 4
      assert game.energy_drain_per_sec == 20
    end
  end

  describe "clear_drain/1" do
    test "clears drain rates" do
      game = Game.new()
      game = Game.set_drain(game, 4, 20)
      game = Game.clear_drain(game)

      assert game.mass_drain_per_sec == 0
      assert game.energy_drain_per_sec == 0
    end
  end

  describe "tick/1" do
    test "applies production and drain" do
      game = Game.new(%{
        mass_storage: 100,
        energy_storage: 500,
        mass_produce_per_sec: 10,
        energy_produce_per_sec: 100
      })
      game = Game.set_drain(game, 4, 20)

      game = Game.tick(game)

      # 100 + 10 - 4 = 106
      assert game.mass_storage == 106
      # 500 + 100 - 20 = 580
      assert game.energy_storage == 580
    end

    test "storage cannot go below zero" do
      game = Game.new(%{
        mass_storage: 5,
        mass_produce_per_sec: 0
      })
      game = Game.set_drain(game, 10, 0)

      game = Game.tick(game)

      assert game.mass_storage == 0
    end

    test "works with zero drain" do
      game = Game.new(%{
        mass_storage: 100,
        mass_produce_per_sec: 10
      })

      game = Game.tick(game)

      assert game.mass_storage == 110
    end
  end

  describe "can_afford?/1" do
    test "returns true when storage >= drain" do
      game = Game.new(%{
        mass_storage: 100,
        energy_storage: 500
      })
      game = Game.set_drain(game, 10, 50)

      assert Game.can_afford?(game)
    end

    test "returns false when storage < drain" do
      game = Game.new(%{
        mass_storage: 5,
        energy_storage: 500
      })
      game = Game.set_drain(game, 10, 50)

      refute Game.can_afford?(game)
    end
  end

  describe "status/1" do
    test "returns current status" do
      game = Game.new(%{
        mass_storage: 650,
        energy_storage: 2500,
        mass_produce_per_sec: 10,
        energy_produce_per_sec: 100
      })
      game = Game.set_drain(game, 4, 20)

      status = Game.status(game)

      assert status.mass_storage == 650
      assert status.energy_storage == 2500
      assert status.mass_produce_per_sec == 10
      assert status.energy_produce_per_sec == 100
      assert status.mass_drain_per_sec == 4
      assert status.energy_drain_per_sec == 20
      assert status.mass_net_per_sec == 6
      assert status.energy_net_per_sec == 80
      assert status.draining == true
    end
  end
end
