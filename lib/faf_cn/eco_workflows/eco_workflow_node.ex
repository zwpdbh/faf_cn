defmodule FafCn.EcoWorkflows.EcoWorkflowNode do
  @moduledoc """
  Schema for eco workflow nodes.

  Stores node configuration without position (LiveFlow auto-layout handles positioning).
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias FafCn.EcoWorkflows.EcoWorkflow

  schema "eco_workflow_nodes" do
    field :node_id, :string
    field :node_type, :string
    field :unit_id, :string
    field :quantity, :integer, default: 1
    field :pos_x, :float, default: 0.0
    field :pos_y, :float, default: 0.0

    belongs_to :workflow, EcoWorkflow, foreign_key: :eco_workflow_id

    timestamps()
  end

  @doc false
  def changeset(node, attrs) do
    node
    |> cast(attrs, [:node_id, :node_type, :unit_id, :quantity, :pos_x, :pos_y, :eco_workflow_id])
    |> validate_required([:node_id, :node_type, :eco_workflow_id])
    |> validate_inclusion(:node_type, ["initial", "unit"])
    |> validate_number(:quantity, greater_than: 0)
    |> foreign_key_constraint(:eco_workflow_id)
    |> unique_constraint([:eco_workflow_id, :node_id])
  end
end
