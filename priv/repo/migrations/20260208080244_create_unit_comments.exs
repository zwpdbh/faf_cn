defmodule FafCn.Repo.Migrations.CreateUnitComments do
  use Ecto.Migration

  def change do
    create table(:unit_comments) do
      add :unit_id, references(:units, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :content, :text, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:unit_comments, [:unit_id])
    create index(:unit_comments, [:user_id])
    create index(:unit_comments, [:unit_id, :inserted_at])
  end
end
