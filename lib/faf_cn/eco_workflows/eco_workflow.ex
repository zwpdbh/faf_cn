defmodule FafCn.EcoWorkflows.EcoWorkflow do
  @moduledoc """
  Schema for eco workflow definitions.

  Stores the workflow metadata and has_many nodes and edges.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias FafCn.Accounts.User
  alias FafCn.EcoWorkflows.{EcoWorkflowNode, EcoWorkflowEdge}

  schema "eco_workflows" do
    field :name, :string

    belongs_to :user, User
    has_many :nodes, EcoWorkflowNode, on_delete: :delete_all
    has_many :edges, EcoWorkflowEdge, on_delete: :delete_all

    timestamps()
  end

  @doc false
  def changeset(workflow, attrs) do
    workflow
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name, :user_id])
    |> validate_length(:name, min: 1, max: 100)
    |> foreign_key_constraint(:user_id)
  end
end
