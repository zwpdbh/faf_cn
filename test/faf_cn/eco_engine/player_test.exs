defmodule FafCn.EcoEngine.PlayerTest do
  @moduledoc """
  Tests for Player - decision maker.
  """
  use ExUnit.Case, async: true

  alias FafCn.EcoEngine.Player

  # T1 Engineer stats
  @t1_eng_mass 52
  @t1_eng_power 260
  @t1_eng_time 130

  describe "new/1 - Initialization" do
    test "creates with defaults" do
      player = Player.new()

      assert player.target_mass == nil
      assert player.target_power == nil
      assert player.target_build_time == nil
      assert player.build_power == 0
      assert player.idle == true
    end

    test "accepts target stats" do
      player =
        Player.new(%{
          target_mass: @t1_eng_mass,
          target_power: @t1_eng_power,
          target_build_time: @t1_eng_time,
          build_power: 10,
          idle: false
        })

      assert player.target_mass == @t1_eng_mass
      assert player.target_power == @t1_eng_power
      assert player.target_build_time == @t1_eng_time
      assert player.build_power == 10
      assert player.idle == false
    end

    test "defaults to idle" do
      player = Player.new(%{build_power: 10})
      assert player.idle == true
    end
  end

  describe "start_build/1 and stop_build/1" do
    test "starts building" do
      player = Player.new()
      player = Player.start_build(player)

      assert player.idle == false
      assert Player.building?(player)
    end

    test "stops building" do
      player = Player.new(%{idle: false})
      player = Player.stop_build(player)

      assert player.idle == true
      refute Player.building?(player)
    end
  end

  describe "drain calculations" do
    test "calculates drain when building" do
      player =
        Player.new(%{
          target_mass: @t1_eng_mass,
          target_power: @t1_eng_power,
          target_build_time: @t1_eng_time,
          build_power: 10,
          idle: false
        })

      # (52 / 130) * 10 = 4.0
      assert Player.mass_drain_per_sec(player) == 4.0
      # (260 / 130) * 10 = 20.0
      assert Player.energy_drain_per_sec(player) == 20.0
    end

    test "returns 0 drain when idle" do
      player =
        Player.new(%{
          target_mass: @t1_eng_mass,
          target_power: @t1_eng_power,
          target_build_time: @t1_eng_time,
          build_power: 10,
          idle: true
        })

      assert Player.mass_drain_per_sec(player) == 0.0
      assert Player.energy_drain_per_sec(player) == 0.0
    end

    test "returns 0 drain when no target" do
      player = Player.new(%{build_power: 10, idle: false})

      assert Player.mass_drain_per_sec(player) == 0.0
      assert Player.energy_drain_per_sec(player) == 0.0
    end
  end

  describe "has_target?/1" do
    test "returns true when all target stats set" do
      player =
        Player.new(%{
          target_mass: @t1_eng_mass,
          target_power: @t1_eng_power,
          target_build_time: @t1_eng_time
        })

      assert Player.has_target?(player)
    end

    test "returns false when missing target stats" do
      player = Player.new(%{target_mass: @t1_eng_mass})
      refute Player.has_target?(player)
    end
  end

  describe "status/1" do
    test "returns full status" do
      player =
        Player.new(%{
          target_mass: @t1_eng_mass,
          target_power: @t1_eng_power,
          target_build_time: @t1_eng_time,
          build_power: 10,
          idle: false
        })

      status = Player.status(player)

      assert status.target_mass == @t1_eng_mass
      assert status.target_power == @t1_eng_power
      assert status.target_build_time == @t1_eng_time
      assert status.build_power == 10
      assert status.idle == false
      assert status.building == true
      assert status.has_target == true
      assert status.mass_drain_per_sec == 4.0
      assert status.energy_drain_per_sec == 20.0
    end
  end
end
