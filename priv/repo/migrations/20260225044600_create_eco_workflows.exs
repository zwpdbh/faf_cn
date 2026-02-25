defmodule FafCn.Repo.Migrations.CreateEcoWorkflows do
  use Ecto.Migration

  def change do
    # Main workflows table
    create table(:eco_workflows) do
      add :name, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:eco_workflows, [:user_id])

    # Workflow nodes (without position - let LiveFlow auto-layout)
    create table(:eco_workflow_nodes) do
      add :eco_workflow_id, references(:eco_workflows, on_delete: :delete_all), null: false
      add :node_id, :string, null: false
      add :node_type, :string, null: false
      add :unit_id, :string
      add :quantity, :integer, default: 1

      timestamps()
    end

    create index(:eco_workflow_nodes, [:eco_workflow_id])
    create unique_index(:eco_workflow_nodes, [:eco_workflow_id, :node_id])
    create index(:eco_workflow_nodes, [:unit_id])

    # Workflow edges (connections between nodes)
    create table(:eco_workflow_edges) do
      add :eco_workflow_id, references(:eco_workflows, on_delete: :delete_all), null: false
      add :edge_id, :string, null: false
      add :source_node_id, :string, null: false
      add :target_node_id, :string, null: false

      timestamps()
    end

    create index(:eco_workflow_edges, [:eco_workflow_id])
    create unique_index(:eco_workflow_edges, [:eco_workflow_id, :edge_id])
  end
end
