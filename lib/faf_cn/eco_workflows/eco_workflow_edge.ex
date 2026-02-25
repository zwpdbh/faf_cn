defmodule FafCn.EcoWorkflows.EcoWorkflowEdge do
  @moduledoc """
  Schema for eco workflow edges (connections between nodes).

  Stores the source and target node references.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias FafCn.EcoWorkflows.EcoWorkflow

  schema "eco_workflow_edges" do
    field :edge_id, :string
    field :source_node_id, :string
    field :target_node_id, :string

    belongs_to :workflow, EcoWorkflow, foreign_key: :eco_workflow_id

    timestamps()
  end

  @doc false
  def changeset(edge, attrs) do
    edge
    |> cast(attrs, [:edge_id, :source_node_id, :target_node_id, :eco_workflow_id])
    |> validate_required([:edge_id, :source_node_id, :target_node_id, :eco_workflow_id])
    |> foreign_key_constraint(:eco_workflow_id)
    |> unique_constraint([:eco_workflow_id, :edge_id])
  end
end
