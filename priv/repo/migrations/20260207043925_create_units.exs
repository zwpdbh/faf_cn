defmodule FafCn.Repo.Migrations.CreateUnits do
  use Ecto.Migration

  def change do
    create table(:units) do
      add :unit_id, :string, null: false
      add :faction, :string, null: false
      add :name, :string
      add :description, :string
      add :build_cost_mass, :integer, null: false
      add :build_cost_energy, :integer, null: false
      add :build_time, :integer, null: false
      add :categories, {:array, :string}, default: []
      add :data, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:units, [:unit_id])
    create index(:units, [:faction])
  end
end
