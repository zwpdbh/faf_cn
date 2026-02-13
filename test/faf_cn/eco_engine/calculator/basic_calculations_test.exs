defmodule FafCn.EcoEngine.Calculator.BasicCalculationsTest do
  @moduledoc """
  Tests for R3: Build Power Calculation and basic calculation functions.

  Requirements covered:
  - R3.1: Base build power formula
  - R3.2: Factory BP + assisting engineers
  - R3.3: Handle zero engineers
  """
  use ExUnit.Case, async: true

  alias FafCn.EcoEngine.Calculator

  describe "R3.1: calculate_build_power/1 - base engineer BP" do
    test "T1 engineers: 5 BP each" do
      engineers = %{t1: 5, t2: 0, t3: 0}
      # 5 * 5 = 25 BP
      assert Calculator.calculate_build_power(engineers) == 25
    end

    test "T2 engineers: 10 BP each" do
      engineers = %{t1: 0, t2: 3, t3: 0}
      # 3 * 10 = 30 BP
      assert Calculator.calculate_build_power(engineers) == 30
    end

    test "T3 engineers: 15 BP each" do
      engineers = %{t1: 0, t2: 0, t3: 2}
      # 2 * 15 = 30 BP
      assert Calculator.calculate_build_power(engineers) == 30
    end

    test "mixed engineers: (T1 × 5) + (T2 × 10) + (T3 × 15)" do
      engineers = %{t1: 2, t2: 1, t3: 1}
      # (2 * 5) + (1 * 10) + (1 * 15) = 10 + 10 + 15 = 35 BP
      assert Calculator.calculate_build_power(engineers) == 35
    end
  end

  describe "R3.3: calculate_build_power/1 - edge cases" do
    test "returns 0 for no engineers" do
      engineers = %{t1: 0, t2: 0, t3: 0}
      assert Calculator.calculate_build_power(engineers) == 0
    end

    test "handles nil values as 0" do
      engineers = %{t1: nil, t2: 2, t3: nil}
      # 0 + 20 + 0 = 20 BP
      assert Calculator.calculate_build_power(engineers) == 20
    end
  end

  describe "calculate_build_time/2" do
    test "calculates simple build time" do
      # Unit with 300 build time, 25 BP
      # 300 / 25 = 12 seconds
      assert Calculator.calculate_build_time(300, 25) == 12
    end

    test "rounds up fractional seconds" do
      # Unit with 100 build time, 30 BP
      # 100 / 30 = 3.33 -> rounds to 4 seconds
      assert Calculator.calculate_build_time(100, 30) == 4
    end

    test "handles zero BP gracefully" do
      assert Calculator.calculate_build_time(300, 0) == :infinity
    end

    test "handles negative BP gracefully" do
      assert Calculator.calculate_build_time(300, -5) == :infinity
    end
  end

  describe "calculate_resource_time/3 - basic" do
    test "calculates time to accumulate resource" do
      # Need 1000 mass, have 0, income 10/s
      assert Calculator.calculate_resource_time(1000, 0, 10) == 100
    end

    test "accounts for starting storage" do
      # Need 1000 mass, have 500, income 10/s
      # (1000 - 500) / 10 = 50 seconds
      assert Calculator.calculate_resource_time(1000, 500, 10) == 50
    end

    test "returns 0 if already have enough" do
      # Need 1000 mass, have 1500, income 10/s
      assert Calculator.calculate_resource_time(1000, 1500, 10) == 0
    end
  end

  describe "calculate_resource_time/3 - edge cases" do
    test "handles zero income when more needed" do
      assert Calculator.calculate_resource_time(1000, 0, 0) == :infinity
    end

    test "returns 0 when have enough even with zero income" do
      assert Calculator.calculate_resource_time(1000, 1500, 0) == 0
    end

    test "handles exact amount" do
      # Need 1000, have 500, income 10/s
      # (1000 - 500) / 10 = 50 exactly
      assert Calculator.calculate_resource_time(1000, 500, 10) == 50
    end
  end
end
