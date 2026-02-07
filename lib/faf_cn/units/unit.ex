defmodule FafCn.Units.Unit do
  @moduledoc """
  Schema for FAF units.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "units" do
    field :unit_id, :string
    field :faction, :string
    field :name, :string
    field :description, :string
    field :build_cost_mass, :integer
    field :build_cost_energy, :integer
    field :build_time, :integer
    field :categories, {:array, :string}
    field :data, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(unit, attrs) do
    unit
    |> cast(attrs, [
      :unit_id,
      :faction,
      :name,
      :description,
      :build_cost_mass,
      :build_cost_energy,
      :build_time,
      :categories,
      :data
    ])
    |> validate_required([:unit_id, :faction, :build_cost_mass, :build_cost_energy, :build_time])
    |> unique_constraint(:unit_id)
  end
end
