defmodule FafCn.Repo.Migrations.CreateUnitEditLogs do
  use Ecto.Migration

  def change do
    create table(:unit_edit_logs) do
      add :unit_id, references(:units, on_delete: :delete_all), null: false
      add :field, :string, null: false
      add :old_value, :string
      add :new_value, :string
      add :reason, :text
      add :edited_by, references(:users, on_delete: :nilify_all), null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:unit_edit_logs, [:unit_id])
    create index(:unit_edit_logs, [:edited_by])
    create index(:unit_edit_logs, [:unit_id, :inserted_at])
  end
end
