defmodule FafCnWeb.EcoWorkflow.Handlers.WorkflowManagement do
  @moduledoc """
  Handles workflow management operations: save, load, rename, delete.
  """

  import Phoenix.Component
  import Phoenix.LiveView, only: [put_flash: 3]

  alias FafCn.EcoWorkflows
  alias FafCn.EcoWorkflows.FlowSerializer

  # ===== Save Operations =====

  @doc """
  Handle save workflow event (save as new).
  """
  def handle_save(socket, %{"name" => name}) do
    if is_nil(socket.assigns.current_user) do
      {:noreply,
       assign(socket,
         save_workflow_error: "You must be logged in to save workflows"
       )}
    else
      flow = socket.assigns.flow
      attrs = FlowSerializer.serialize(flow, name, socket.assigns.current_user.id)

      case EcoWorkflows.create_workflow(attrs, socket.assigns.current_user.id) do
        {:ok, workflow} ->
          saved_workflows = EcoWorkflows.list_workflows(socket.assigns.current_user.id)

          {:noreply,
           socket
           |> assign(
             show_save_workflow: false,
             save_workflow_name: "",
             save_workflow_error: nil,
             saved_workflows: saved_workflows,
             workflow_id: workflow.id,
             workflow_name: workflow.name,
             workflow_dirty: false
           )
           |> put_flash(:info, "Workflow '#{name}' saved successfully")}

        {:error, _changeset} ->
          {:noreply,
           assign(socket,
             save_workflow_error: "Failed to save workflow. Please try again."
           )}
      end
    end
  end

  @doc """
  Handle quick save (update existing workflow).
  """
  def handle_quick_save(socket) do
    user = socket.assigns.current_user
    workflow_id = socket.assigns.workflow_id

    with true <- not is_nil(user),
         true <- not is_nil(workflow_id),
         workflow <- EcoWorkflows.get_workflow!(workflow_id),
         true <- not is_nil(workflow),
         attrs <- build_workflow_attrs(socket),
         {:ok, _updated} <- EcoWorkflows.update_workflow(workflow, attrs) do
      socket
      |> assign(workflow_dirty: false, workflow_saving: false)
      |> put_flash(:info, "Workflow saved")
    else
      _ ->
        socket
        |> assign(workflow_saving: false)
        |> put_flash(:error, "Failed to save workflow")
    end
  end

  @doc """
  Handle auto-save triggered by timer.
  """
  def handle_auto_save(socket) do
    workflow_id = socket.assigns.workflow_id
    dirty = socket.assigns.workflow_dirty

    with true <- not is_nil(workflow_id),
         true <- dirty,
         workflow <- EcoWorkflows.get_workflow!(workflow_id),
         true <- not is_nil(workflow),
         attrs <- build_workflow_attrs(socket),
         {:ok, _updated} <- EcoWorkflows.update_workflow(workflow, attrs) do
      assign(socket,
        workflow_dirty: false,
        workflow_saving: false,
        save_debounce_timer: nil
      )
    else
      _ ->
        socket
        |> assign(workflow_saving: false, save_debounce_timer: nil)
        |> maybe_put_auto_save_error(dirty)
    end
  end

  defp maybe_put_auto_save_error(socket, true) do
    Phoenix.LiveView.put_flash(socket, :error, "Auto-save failed")
  end

  defp maybe_put_auto_save_error(socket, false), do: socket

  defp build_workflow_attrs(socket) do
    FlowSerializer.serialize(
      socket.assigns.flow,
      socket.assigns.workflow_name,
      socket.assigns.current_user.id
    )
  end

  # ===== Load Operations =====

  @doc """
  Handle load workflow event.
  """
  def handle_load(socket, %{"workflow_id" => workflow_id}, units) do
    if is_nil(socket.assigns.current_user) do
      {:noreply,
       Phoenix.LiveView.put_flash(socket, :error, "You must be logged in to load workflows")}
    else
      case EcoWorkflows.get_workflow_for_user(workflow_id, socket.assigns.current_user.id) do
        nil ->
          {:noreply, Phoenix.LiveView.put_flash(socket, :error, "Workflow not found")}

        workflow ->
          flow = FlowSerializer.deserialize(workflow, units)

          {:noreply,
           socket
           |> assign(
             flow: flow,
             simulation_run: false,
             workflow_id: workflow.id,
             workflow_name: workflow.name,
             workflow_dirty: false,
             show_load_workflow: false
           )
           |> put_flash(:info, "Workflow '#{workflow.name}' loaded")}
      end
    end
  end

  @doc """
  List workflows for the current user.
  """
  def list_workflows(socket) do
    if socket.assigns.current_user do
      EcoWorkflows.list_workflows(socket.assigns.current_user.id)
    else
      []
    end
  end

  # ===== Rename Operations =====

  @doc """
  Handle rename workflow event.
  """
  def handle_rename(socket, %{"name" => name}) do
    user = socket.assigns.current_user
    workflow_id = socket.assigns.workflow_id

    if is_nil(user) || is_nil(workflow_id) do
      # Just update local name for unsaved workflows
      socket
      |> assign(
        workflow_name: name,
        show_rename_workflow: false,
        rename_workflow_name: "",
        workflow_dirty: true
      )
    else
      perform_workflow_rename(socket, workflow_id, name)
    end
  end

  defp perform_workflow_rename(socket, workflow_id, name) do
    user_id = socket.assigns.current_user.id

    case EcoWorkflows.get_workflow_for_user(workflow_id, user_id) do
      nil ->
        Phoenix.LiveView.put_flash(socket, :error, "Workflow not found")

      workflow ->
        complete_workflow_rename(socket, workflow, name)
    end
  end

  defp complete_workflow_rename(socket, workflow, name) do
    case EcoWorkflows.rename_workflow(workflow, name) do
      {:ok, updated} ->
        saved_workflows = EcoWorkflows.list_workflows(socket.assigns.current_user.id)

        socket
        |> assign(
          workflow_name: updated.name,
          saved_workflows: saved_workflows,
          show_rename_workflow: false,
          rename_workflow_name: ""
        )
        |> put_flash(:info, "Workflow renamed to '#{name}'")

      {:error, _changeset} ->
        Phoenix.LiveView.put_flash(socket, :error, "Failed to rename workflow")
    end
  end

  # ===== Delete Operations =====

  @doc """
  Handle delete workflow event.
  """
  def handle_delete(socket, _workflow_id) when is_nil(socket.assigns.current_user) do
    Phoenix.LiveView.put_flash(socket, :error, "You must be logged in")
  end

  def handle_delete(socket, workflow_id) do
    user_id = socket.assigns.current_user.id

    case EcoWorkflows.get_workflow_for_user(workflow_id, user_id) do
      nil ->
        Phoenix.LiveView.put_flash(socket, :error, "Workflow not found")

      workflow ->
        complete_workflow_delete(socket, workflow)
    end
  end

  defp complete_workflow_delete(socket, workflow) do
    case EcoWorkflows.delete_workflow(workflow) do
      {:ok, _} ->
        saved_workflows = EcoWorkflows.list_workflows(socket.assigns.current_user.id)
        socket = handle_deleted_workflow(socket, workflow, saved_workflows)
        Phoenix.LiveView.put_flash(socket, :info, "Workflow deleted")

      {:error, _changeset} ->
        Phoenix.LiveView.put_flash(socket, :error, "Failed to delete workflow")
    end
  end

  defp handle_deleted_workflow(socket, deleted_workflow, saved_workflows) do
    if socket.assigns.workflow_id == deleted_workflow.id do
      # Reset to default if current workflow was deleted
      socket
      |> assign(
        workflow_id: nil,
        workflow_name: "Default Workflow",
        workflow_dirty: false,
        saved_workflows: saved_workflows
      )
    else
      assign(socket, saved_workflows: saved_workflows)
    end
  end
end
