defmodule FafCn.EcoWorkflows do
  @moduledoc """
  The EcoWorkflows context.

  Provides functions for creating, reading, updating, and deleting
  eco workflow definitions with real-time sync support.
  """

  import Ecto.Query, warn: false
  alias FafCn.Repo
  alias FafCn.EcoWorkflows.{EcoWorkflow, EcoWorkflowNode, EcoWorkflowEdge}

  @doc """
  Returns the list of eco workflows for a user.

  ## Examples

      iex> list_workflows(user_id)
      [%EcoWorkflow{}, ...]

  """
  def list_workflows(user_id) do
    EcoWorkflow
    |> where(user_id: ^user_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single eco workflow.

  Raises `Ecto.NoResultsError` if the EcoWorkflow does not exist.

  ## Examples

      iex> get_workflow!(123)
      %EcoWorkflow{}

      iex> get_workflow!(456)
      ** (Ecto.NoResultsError)

  """
  def get_workflow!(id) do
    EcoWorkflow
    |> Repo.get!(id)
    |> Repo.preload([:nodes, :edges])
  end

  @doc """
  Gets a single eco workflow if it belongs to the user.

  Returns nil if the workflow doesn't exist or doesn't belong to the user.

  ## Examples

      iex> get_workflow_for_user(123, user_id)
      %EcoWorkflow{}

      iex> get_workflow_for_user(456, other_user_id)
      nil

  """
  def get_workflow_for_user(id, user_id) do
    EcoWorkflow
    |> where(id: ^id, user_id: ^user_id)
    |> preload([:nodes, :edges])
    |> Repo.one()
  end

  @doc """
  Creates a new eco workflow with nodes and edges.

  Returns the created workflow with preloaded associations.

  ## Examples

      iex> create_workflow(%{name: "My Workflow", nodes: [...], edges: [...]}, user_id)
      {:ok, %EcoWorkflow{}}

      iex> create_workflow(%{name: ""}, user_id)
      {:error, %Ecto.Changeset{}}

  """
  def create_workflow(attrs, user_id) do
    nodes = Map.get(attrs, "nodes", [])
    edges = Map.get(attrs, "edges", [])

    workflow_attrs = %{
      "name" => attrs["name"],
      "user_id" => user_id
    }

    Repo.transaction(fn ->
      # Create workflow
      {:ok, workflow} =
        %EcoWorkflow{}
        |> EcoWorkflow.changeset(workflow_attrs)
        |> Repo.insert()

      # Insert nodes
      Enum.each(nodes, fn node_attrs ->
        node_attrs =
          node_attrs
          |> Map.put("eco_workflow_id", workflow.id)
          |> Map.put_new("quantity", 1)

        %EcoWorkflowNode{}
        |> EcoWorkflowNode.changeset(node_attrs)
        |> Repo.insert!()
      end)

      # Insert edges
      Enum.each(edges, fn edge_attrs ->
        edge_attrs = Map.put(edge_attrs, "eco_workflow_id", workflow.id)

        %EcoWorkflowEdge{}
        |> EcoWorkflowEdge.changeset(edge_attrs)
        |> Repo.insert!()
      end)

      # Return workflow with preloaded associations
      workflow |> Repo.preload([:nodes, :edges])
    end)
  end

  @doc """
  Updates an existing workflow by replacing all nodes and edges.
  Used for real-time sync after initial save.

  ## Examples

      iex> update_workflow(workflow, %{nodes: [...], edges: [...]})
      {:ok, %EcoWorkflow{}}

  """
  def update_workflow(%EcoWorkflow{} = workflow, attrs) do
    nodes = Map.get(attrs, "nodes", [])
    edges = Map.get(attrs, "edges", [])

    Repo.transaction(fn ->
      # Delete existing nodes and edges (cascade delete handles edges)
      EcoWorkflowNode
      |> where(eco_workflow_id: ^workflow.id)
      |> Repo.delete_all()

      EcoWorkflowEdge
      |> where(eco_workflow_id: ^workflow.id)
      |> Repo.delete_all()

      # Insert new nodes
      Enum.each(nodes, fn node_attrs ->
        node_attrs =
          node_attrs
          |> Map.put("eco_workflow_id", workflow.id)
          |> Map.put_new("quantity", 1)

        %EcoWorkflowNode{}
        |> EcoWorkflowNode.changeset(node_attrs)
        |> Repo.insert!()
      end)

      # Insert new edges
      Enum.each(edges, fn edge_attrs ->
        edge_attrs = Map.put(edge_attrs, "eco_workflow_id", workflow.id)

        %EcoWorkflowEdge{}
        |> EcoWorkflowEdge.changeset(edge_attrs)
        |> Repo.insert!()
      end)

      # Return workflow with preloaded associations
      workflow |> Repo.preload([:nodes, :edges], force: true)
    end)
  end

  @doc """
  Updates workflow name.

  ## Examples

      iex> rename_workflow(workflow, "New Name")
      {:ok, %EcoWorkflow{}}

  """
  def rename_workflow(%EcoWorkflow{} = workflow, new_name) do
    workflow
    |> EcoWorkflow.changeset(%{"name" => new_name})
    |> Repo.update()
  end

  @doc """
  Updates node positions for a workflow. Lightweight update for position changes only.

  ## Examples

      iex> update_node_positions(workflow_id, %{"node-1" => %{x: 100, y: 200}, ...})
      :ok

  """
  def update_node_positions(workflow_id, positions_map) when is_map(positions_map) do
    Enum.each(positions_map, fn {node_id, pos} ->
      EcoWorkflowNode
      |> where(eco_workflow_id: ^workflow_id, node_id: ^node_id)
      |> Repo.update_all(set: [pos_x: pos.x, pos_y: pos.y])
    end)

    :ok
  end

  @doc """
  Deletes an eco workflow.

  ## Examples

      iex> delete_workflow(workflow)
      {:ok, %EcoWorkflow{}}

      iex> delete_workflow(workflow)
      {:error, %Ecto.Changeset{}}

  """
  def delete_workflow(%EcoWorkflow{} = workflow) do
    Repo.delete(workflow)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking workflow changes.

  ## Examples

      iex> change_workflow(workflow)
      %Ecto.Changeset{data: %EcoWorkflow{}}

  """
  def change_workflow(%EcoWorkflow{} = workflow, attrs \\ %{}) do
    EcoWorkflow.changeset(workflow, attrs)
  end

  @doc """
  Counts the number of nodes in a workflow.
  """
  def count_workflow_nodes(workflow_id) do
    EcoWorkflowNode
    |> where(eco_workflow_id: ^workflow_id)
    |> Repo.aggregate(:count, :id)
  end
end
