defmodule FafCn.Repo.Migrations.AddPositionToWorkflowNodes do
  use Ecto.Migration

  def change do
    alter table(:eco_workflow_nodes) do
      add :pos_x, :float, default: 0.0
      add :pos_y, :float, default: 0.0
    end
  end
end
