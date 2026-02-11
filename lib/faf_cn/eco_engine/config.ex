defmodule FafCn.EcoEngine.Config do
  @moduledoc """
  Configuration for eco simulation.
  Defines starting conditions and mex setup.
  """

  defstruct [
    :t1_mex_count,
    :t2_mex_count,
    :t3_mex_count,
    :mass_storage,
    :energy_storage,
    :build_order
  ]

  @type t :: %__MODULE__{
          t1_mex_count: non_neg_integer(),
          t2_mex_count: non_neg_integer(),
          t3_mex_count: non_neg_integer(),
          mass_storage: non_neg_integer(),
          energy_storage: non_neg_integer(),
          build_order: list(map())
        }

  @doc """
  Creates a new config with defaults.
  """
  def new(attrs \\ %{}) do
    %__MODULE__{
      t1_mex_count: attrs[:t1_mex_count] || 2,
      t2_mex_count: attrs[:t2_mex_count] || 0,
      t3_mex_count: attrs[:t3_mex_count] || 0,
      mass_storage: attrs[:mass_storage] || 650,
      energy_storage: attrs[:energy_storage] || 2500,
      build_order: attrs[:build_order] || []
    }
  end

  @doc """
  Calculates total mass income per second from all mex.
  """
  def mass_income_per_tick(%__MODULE__{} = config) do
    t1_income = config.t1_mex_count * 2
    t2_income = config.t2_mex_count * 6
    t3_income = config.t3_mex_count * 18
    t1_income + t2_income + t3_income
  end
end
