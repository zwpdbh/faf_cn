defmodule FafCn.Repo.Migrations.RenameEditedByToEditedById do
  use Ecto.Migration

  def change do
    rename table(:unit_edit_logs), :edited_by, to: :edited_by_id
  end
end
