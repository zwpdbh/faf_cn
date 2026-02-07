defmodule FafCn.Repo.Migrations.AddUnitIconPath do
  use Ecto.Migration

  def change do
    alter table(:units) do
      add :icon_path, :string
    end

    create index(:units, [:icon_path])
  end
end
