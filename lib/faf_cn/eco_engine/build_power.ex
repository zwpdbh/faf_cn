defmodule FafCn.EcoEngine.BuildPower do
  @moduledoc """
  Pure functions for build power calculations in the eco engine.

  This module contains the core mathematical formulas for:
  - Calculating resource drain rates per build power
  - Determining BP limits based on resource availability
  - Computing build times with and without storage buffers

  All functions are pure (no side effects) and work with float values
  for precise calculations.
  """

  @typedoc "Resource cost and build time for a unit"
  @type unit_stats :: %{
          mass: float(),
          energy: float(),
          build_time: float()
        }

  @typedoc "Resource production rates per second"
  @type resource_production :: %{
          mass: float(),
          energy: float()
        }

  @typedoc "Resource storage levels"
  @type resource_storage :: %{
          mass: float(),
          energy: float()
        }

  @doc """
  Calculate resource drain per BP per second.

  ## Formula
      drain_per_bp = unit_cost / unit_build_time

  ## Examples

      iex> BuildPower.drain_per_bp(28_000, 47_500)
      0.5894736842105263

      iex> BuildPower.drain_per_bp(350_000, 47_500)
      7.368421052631579
  """
  @spec drain_per_bp(float(), float()) :: float()
  def drain_per_bp(unit_cost, unit_build_time) do
    if unit_build_time > 0 do
      unit_cost / unit_build_time
    else
      0.0
    end
  end

  @doc """
  Calculate the BP limit imposed by a specific resource.

  ## Formula
      bp_limited = resource_produce / drain_per_bp

  ## Examples

      iex> mass_drain = BuildPower.drain_per_bp(28_000, 47_500)
      iex> BuildPower.bp_limited_by_resource(40, mass_drain) |> Float.round(2)
      67.86
  """
  @spec bp_limited_by_resource(float(), float()) :: float()
  def bp_limited_by_resource(resource_produce, drain_per_bp) do
    if drain_per_bp > 0 do
      resource_produce / drain_per_bp
    else
      0.0
    end
  end

  @doc """
  Calculate the actual BP available given resource constraints.

  The actual BP is the minimum of:
  - Available BP (from engineers)
  - BP limited by mass production
  - BP limited by energy production

  ## Formula
      actual_bp = min(available_bp, bp_limited_by_mass, bp_limited_by_energy)

  ## Examples

      # Mass-limited scenario
      iex> BuildPower.actual_bp(150, 67.86, 162.86)
      67.86

      # BP-limited scenario (not resource constrained)
      iex> BuildPower.actual_bp(150, 200.0, 300.0)
      150.0
  """
  @spec actual_bp(float(), float(), float()) :: float()
  def actual_bp(available_bp, bp_limited_by_mass, bp_limited_by_energy) do
    min(available_bp, min(bp_limited_by_mass, bp_limited_by_energy))
  end

  @doc """
  Calculate build time in ticks given target build time and actual BP.

  ## Formula
      ticks = target_build_time / actual_bp

  ## Examples

      # Fatboy with 150 BP (infinite resources)
      iex> BuildPower.ticks_needed(47_500, 150) |> Float.round(2)
      316.67

      # Fatboy mass-limited to 67.86 BP
      iex> BuildPower.ticks_needed(47_500, 67.86) |> Float.round(2)
      700.0
  """
  @spec ticks_needed(float(), float()) :: float() | :infinity
  def ticks_needed(target_build_time, actual_bp) do
    if actual_bp > 0 do
      target_build_time / actual_bp
    else
      :infinity
    end
  end

  @doc """
  Calculate how long storage lasts when draining at full BP.

  ## Formula
      depletion_time = storage / (drain_at_full_bp - production)

  Returns `:infinity` if net drain is not positive (storage never depletes).

  ## Examples

      # Mass storage depletes
      iex> BuildPower.storage_depletion_time(14_000, 88.42, 40) |> Float.round(2)
      289.14

      # Energy storage never depletes (production > drain)
      iex> BuildPower.storage_depletion_time(175_000, 1105.26, 1200)
      :infinity
  """
  @spec storage_depletion_time(float(), float(), float()) :: float() | :infinity
  def storage_depletion_time(storage, drain_at_full_bp, production) do
    net_drain = drain_at_full_bp - production

    if net_drain > 0 do
      storage / net_drain
    else
      :infinity
    end
  end

  @doc """
  Calculate total build progress achieved during storage phase.

  ## Formula
      progress = full_bp * depletion_time

  ## Examples

      iex> BuildPower.phase1_progress(150, 289.14)
      43371.0
  """
  @spec phase1_progress(float(), float()) :: float()
  def phase1_progress(full_bp, depletion_time) do
    full_bp * depletion_time
  end

  @doc """
  Calculate remaining progress after storage phase.

  ## Formula
      remaining = target_build_time - phase1_progress

  ## Examples

      iex> BuildPower.remaining_progress(47_500, 43_365)
      4135.0
  """
  @spec remaining_progress(float(), float()) :: float()
  def remaining_progress(target_build_time, phase1_progress) do
    target_build_time - phase1_progress
  end

  @doc """
  Calculate time needed for phase 2 (income-limited) of build.

  ## Formula
      phase2_ticks = remaining_progress / bp_limited_by_resource

  ## Examples

      iex> BuildPower.phase2_ticks(4_135, 67.86) |> Float.round(2)
      60.93
  """
  @spec phase2_ticks(float(), float()) :: float()
  def phase2_ticks(remaining_progress, bp_limited) do
    if bp_limited > 0 do
      remaining_progress / bp_limited
    else
      :infinity
    end
  end

  @doc """
  Calculate total build time with storage buffer (two-phase build).

  If storage never depletes, returns theoretical build time with full BP.

  ## Parameters
    - target_build_time: Unit's build time stat
    - available_bp: Total BP from engineers
    - mass_produce: Mass income per second
    - energy_produce: Energy income per second
    - mass_storage: Initial mass storage
    - energy_storage: Initial energy storage

  ## Returns
    - Total ticks needed to complete build

  ## Examples

      # Fatboy with 14k mass storage (mass-limited after storage)
      iex> BuildPower.two_phase_build_time(
      ...>   47_500, 150, 40, 1200, 14_000, 175_000
      ...> ) |> Float.round(0)
      350.0

      # Fatboy with 175k energy storage (energy-limited after storage)
      iex> BuildPower.two_phase_build_time(
      ...>   47_500, 150, 100, 800, 14_000, 175_000
      ...> ) |> Float.round(2)
      316.67
  """
  @spec two_phase_build_time(
          target_build_time :: float(),
          available_bp :: float(),
          mass_produce :: float(),
          energy_produce :: float(),
          mass_storage :: float(),
          energy_storage :: float()
        ) :: float()
  def two_phase_build_time(
        target_build_time,
        available_bp,
        mass_produce,
        energy_produce,
        mass_storage,
        energy_storage
      ) do
    # Calculate drain per BP for Fatboy (assumed constant)
    mass_drain_per_bp = drain_per_bp(28_000.0, target_build_time)
    energy_drain_per_bp = drain_per_bp(350_000.0, target_build_time)

    # Full BP drain rates
    full_mass_drain = mass_drain_per_bp * available_bp
    full_energy_drain = energy_drain_per_bp * available_bp

    # BP limits from income
    bp_limited_by_mass = bp_limited_by_resource(mass_produce, mass_drain_per_bp)
    bp_limited_by_energy = bp_limited_by_resource(energy_produce, energy_drain_per_bp)

    # Calculate depletion times
    mass_depletion_time = storage_depletion_time(mass_storage, full_mass_drain, mass_produce)

    energy_depletion_time =
      storage_depletion_time(energy_storage, full_energy_drain, energy_produce)

    compute_two_phase_time(
      target_build_time,
      available_bp,
      bp_limited_by_mass,
      bp_limited_by_energy,
      mass_depletion_time,
      energy_depletion_time
    )
  end

  # Determine which resource depletes first and compute total time
  defp compute_two_phase_time(
         target_time,
         available_bp,
         mass_limit,
         energy_limit,
         mass_time,
         energy_time
       ) do
    first_depletion = first_depletion(mass_time, energy_time)

    case first_depletion do
      :never ->
        ticks_needed(target_time, available_bp)

      {resource, depletion_time} ->
        compute_phased_build_time(
          target_time,
          available_bp,
          resource,
          depletion_time,
          mass_limit,
          energy_limit
        )
    end
  end

  # Determine which storage depletes first
  defp first_depletion(:infinity, :infinity), do: :never
  defp first_depletion(:infinity, t), do: {:energy, t}
  defp first_depletion(t, :infinity), do: {:mass, t}
  defp first_depletion(t1, t2) when t1 <= t2, do: {:mass, t1}
  defp first_depletion(_, t2), do: {:energy, t2}

  # Compute total time given depletion info
  defp compute_phased_build_time(
         target_time,
         available_bp,
         resource,
         depletion_time,
         mass_limit,
         energy_limit
       ) do
    p1_progress = phase1_progress(available_bp, depletion_time)

    if build_completes_in_phase1?(target_time, p1_progress) do
      ticks_needed(target_time, available_bp)
    else
      phase2_time(
        target_time,
        available_bp,
        resource,
        depletion_time,
        p1_progress,
        mass_limit,
        energy_limit
      )
    end
  end

  defp build_completes_in_phase1?(target_time, phase1_progress),
    do: phase1_progress >= target_time

  defp phase2_time(
         target_time,
         available_bp,
         resource,
         depletion_time,
         p1_progress,
         mass_limit,
         energy_limit
       ) do
    p2_bp = phase2_bp(resource, available_bp, mass_limit, energy_limit)
    p2_progress = remaining_progress(target_time, p1_progress)
    p2_ticks = phase2_ticks(p2_progress, p2_bp)

    depletion_time + p2_ticks
  end

  defp phase2_bp(:mass, available, mass_limit, _), do: min(available, mass_limit)
  defp phase2_bp(:energy, available, _, energy_limit), do: min(available, energy_limit)

  @doc """
  Calculate complete build metrics for a scenario.

  Returns a map with all intermediate calculations for analysis.

  ## Examples

      iex> metrics = BuildPower.calculate_metrics(
      ...>   %{mass: 28_000, energy: 350_000, build_time: 47_500},
      ...>   150,
      ...>   %{mass: 40, energy: 1200},
      ...>   %{mass: 14_000, energy: 175_000}
      ...> )
      iex> metrics.actual_bp |> Float.round(2)
      67.86
      iex> metrics.total_ticks |> Float.round(0)
      350.0
  """
  @spec calculate_metrics(unit_stats(), float(), resource_production(), resource_storage()) :: %{
          drain_per_bp: %{mass: float(), energy: float()},
          bp_limited_by: %{mass: float(), energy: float()},
          actual_bp: float(),
          phase1: %{
            depletes: atom(),
            time: float() | :infinity,
            progress: float()
          },
          phase2: %{
            bp: float(),
            time: float()
          },
          total_ticks: float()
        }
  def calculate_metrics(unit_stats, available_bp, production, storage) do
    # Drain per BP
    mass_drain_per_bp = drain_per_bp(unit_stats.mass, unit_stats.build_time)
    energy_drain_per_bp = drain_per_bp(unit_stats.energy, unit_stats.build_time)

    # Full BP drain
    full_mass_drain = mass_drain_per_bp * available_bp
    full_energy_drain = energy_drain_per_bp * available_bp

    # BP limits
    bp_limited_by_mass = bp_limited_by_resource(production.mass, mass_drain_per_bp)
    bp_limited_by_energy = bp_limited_by_resource(production.energy, energy_drain_per_bp)

    # Actual BP (income-limited)
    actual_income_limited = actual_bp(available_bp, bp_limited_by_mass, bp_limited_by_energy)

    # Depletion times
    mass_depletion_time = storage_depletion_time(storage.mass, full_mass_drain, production.mass)

    energy_depletion_time =
      storage_depletion_time(storage.energy, full_energy_drain, production.energy)

    # Phase calculations
    phase1 = calculate_phase1(available_bp, mass_depletion_time, energy_depletion_time)

    phase2 =
      calculate_phase2(
        unit_stats.build_time,
        available_bp,
        phase1,
        bp_limited_by_mass,
        bp_limited_by_energy
      )

    total_ticks = calculate_total_ticks(unit_stats.build_time, available_bp, phase1, phase2)

    %{
      drain_per_bp: %{mass: mass_drain_per_bp, energy: energy_drain_per_bp},
      bp_limited_by: %{mass: bp_limited_by_mass, energy: bp_limited_by_energy},
      actual_bp: actual_income_limited,
      phase1: phase1,
      phase2: phase2,
      total_ticks: total_ticks
    }
  end

  defp calculate_phase1(available_bp, mass_time, energy_time) do
    {limiting, first_depletion} = determine_limiting_resource(mass_time, energy_time)

    progress =
      if first_depletion == :infinity, do: 0, else: phase1_progress(available_bp, first_depletion)

    %{
      depletes: limiting,
      time: first_depletion,
      progress: progress
    }
  end

  defp determine_limiting_resource(:infinity, :infinity), do: {:none, :infinity}
  defp determine_limiting_resource(:infinity, t), do: {:energy, t}
  defp determine_limiting_resource(t, :infinity), do: {:mass, t}
  defp determine_limiting_resource(t1, t2) when t1 <= t2, do: {:mass, t1}
  defp determine_limiting_resource(_, t2), do: {:energy, t2}

  defp calculate_phase2(target_time, available_bp, phase1, mass_limit, energy_limit) do
    if phase1.progress >= target_time do
      %{bp: available_bp, time: 0}
    else
      p2_bp = phase2_bp_for_resource(phase1.depletes, available_bp, mass_limit, energy_limit)
      p2_progress = remaining_progress(target_time, phase1.progress)
      %{bp: p2_bp, time: phase2_ticks(p2_progress, p2_bp)}
    end
  end

  defp phase2_bp_for_resource(:mass, available, mass_limit, _), do: min(available, mass_limit)

  defp phase2_bp_for_resource(:energy, available, _, energy_limit),
    do: min(available, energy_limit)

  defp phase2_bp_for_resource(:none, available, _, _), do: available

  defp calculate_total_ticks(target_time, available_bp, phase1, phase2) do
    cond do
      phase1.time == :infinity ->
        ticks_needed(target_time, available_bp)

      phase1.progress >= target_time ->
        ticks_needed(target_time, available_bp)

      true ->
        phase1.time + phase2.time
    end
  end
end
