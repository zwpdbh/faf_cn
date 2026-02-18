defmodule FafCn.EcoEngine.Builder do
  @moduledoc """
  Builder Agent - executes build orders and tracks construction progress.

  ## Build Progress Model

  Each unit has a `build_time` (in "build seconds"):
  - This is the time it would take to build with 1 Build Power (BP)
  - Example: T1 Engineer has build_time: 130

  With more BP, units build proportionally faster:
  - 5 T1 engineers = 10 BP → 130 / 10 = 13 seconds actual time
  - 10 T3 engineers = 150 BP → 130 / 150 = 0.87 seconds actual time

  ## Progress Tracking

  Progress is tracked in "build seconds completed":
  - progress: 0 → build just started
  - progress: 65 → 50% done (for 130s build time)
  - progress: 130 → 100% done, unit complete

  Each tick: `progress += total_bp`

  ## Resource Drain Calculation

  Resource consumption is based on progress made:
  - mass_drain_per_tick = (mass_cost / build_time) * total_bp
  - energy_drain_per_tick = (energy_cost / build_time) * total_bp

  This means drain is proportional to BP used.
  """

  defstruct [
    :current_target,
    :build_time,
    :progress,
    :total_bp,
    :mass_drain,
    :energy_drain,
    :status
  ]

  @type t :: %__MODULE__{
          current_target: map() | nil,
          build_time: integer(),
          progress: integer(),
          total_bp: integer(),
          mass_drain: integer(),
          energy_drain: integer(),
          status: :idle | :building | :stalled
        }

  @doc """
  Create new Builder with available build power.

  ## Options
  - `engineers`: Map of engineer counts by tier
    - `t1`: number of T1 engineers (2 BP each)
    - `t2`: number of T2 engineers (5 BP each)  
    - `t3`: number of T3 engineers (15 BP each)
  """
  def new(opts \\ %{}) do
    total_bp = calculate_total_bp(opts[:engineers] || %{})

    %__MODULE__{
      current_target: nil,
      build_time: 0,
      progress: 0,
      total_bp: total_bp,
      mass_drain: 0,
      energy_drain: 0,
      status: :idle
    }
  end

  @doc """
  Start building a new unit.

  Returns updated builder state and consumption info for Observer.
  """
  def start_build(builder, unit) do
    if builder.status != :idle do
      raise "Cannot start new build while already building"
    end

    build_time = unit.build_time
    unit_mass_cost = unit.build_cost_mass
    unit_energy_cost = unit.build_cost_energy

    # Calculate per-tick drain based on BP and build time
    # drain_per_tick = (total_cost / build_time) * total_bp
    mass_drain = div(unit_mass_cost * builder.total_bp, build_time)
    energy_drain = div(unit_energy_cost * builder.total_bp, build_time)

    new_builder = %{
      builder
      | current_target: unit,
        build_time: build_time,
        progress: 0,
        mass_drain: mass_drain,
        energy_drain: energy_drain,
        status: :building
    }

    # Return builder and consumption report for Observer
    {
      new_builder,
      %{mass_drain: mass_drain, energy_drain: energy_drain}
    }
  end

  @doc """
  Advance build progress by one tick.

  Returns:
  - `{builder, :continue, drain}` - build in progress
  - `{builder, :completed, unit}` - build finished
  - `{builder, :stalled, drain}` - build paused (not enough resources)
  """
  def tick(builder, resources_available) do
    case builder.status do
      :idle ->
        {builder, :idle, %{mass_drain: 0, energy_drain: 0}}

      :stalled ->
        # Try to resume if resources available
        if can_build?(builder, resources_available) do
          builder = %{builder | status: :building}
          do_build_tick(builder)
        else
          drain = calculate_drain(builder)
          {builder, :stalled, drain}
        end

      :building ->
        if can_build?(builder, resources_available) do
          do_build_tick(builder)
        else
          builder = %{builder | status: :stalled}
          drain = calculate_drain(builder)
          {builder, :stalled, drain}
        end
    end
  end

  @doc """
  Get current build progress as percentage (0-100).
  """
  def progress_percent(builder) do
    if builder.build_time == 0 do
      0
    else
      div(builder.progress * 100, builder.build_time)
    end
  end

  @doc """
  Check if builder is currently idle.
  """
  def idle?(builder) do
    builder.status == :idle
  end

  # Private functions

  defp calculate_total_bp(engineers) do
    t1_bp = Map.get(engineers, :t1, 0) * 2
    t2_bp = Map.get(engineers, :t2, 0) * 5
    t3_bp = Map.get(engineers, :t3, 0) * 15

    t1_bp + t2_bp + t3_bp
  end

  defp can_build?(builder, resources) do
    drain = calculate_drain(builder)

    resources.mass_storage >= drain.mass_drain and
      resources.energy_storage >= drain.energy_drain
  end

  defp calculate_drain(builder) do
    if builder.status == :idle do
      %{mass_drain: 0, energy_drain: 0}
    else
      %{mass_drain: builder.mass_drain, energy_drain: builder.energy_drain}
    end
  end

  defp do_build_tick(builder) do
    new_progress = builder.progress + builder.total_bp
    drain = calculate_drain(builder)

    if new_progress >= builder.build_time do
      # Build complete!
      completed_unit = builder.current_target

      new_builder = %{
        builder
        | current_target: nil,
          build_time: 0,
          progress: 0,
          mass_drain: 0,
          energy_drain: 0,
          status: :idle
      }

      {new_builder, {:completed, completed_unit}, drain}
    else
      new_builder = %{builder | progress: new_progress}
      {new_builder, :continue, drain}
    end
  end
end
