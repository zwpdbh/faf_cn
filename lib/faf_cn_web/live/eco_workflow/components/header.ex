defmodule FafCnWeb.EcoWorkflow.Components.Header do
  @moduledoc """
  Header component for the Eco Workflow page.
  Contains workflow name dropdown, status indicator, and action buttons.
  """
  use FafCnWeb, :html

  alias Phoenix.LiveView.JS

  attr :current_user, :any, required: true
  attr :workflow_name, :string, required: true
  attr :workflow_dirty, :boolean, required: true
  attr :workflow_saving, :boolean, required: true
  attr :workflow_id, :any, required: true
  attr :simulation_run, :boolean, required: true

  def workflow_header(assigns) do
    ~H"""
    <div class="p-4 bg-base-200 border-b border-base-300">
      <div class="flex items-center">
        <%!-- Left: Title & Workflow Info --%>
        <div class="w-80 shrink-0">
          <div class="flex items-center gap-2">
            <h1 class="text-xl font-bold">Eco Workflow</h1>
            <%= if @current_user do %>
              <.workflow_name_dropdown
                workflow_name={@workflow_name}
                workflow_dirty={@workflow_dirty}
                workflow_id={@workflow_id}
              />
            <% else %>
              <span class="text-sm text-base-content/60">{@workflow_name}</span>
            <% end %>
          </div>
          <.status_indicator
            workflow_saving={@workflow_saving}
            workflow_dirty={@workflow_dirty}
            workflow_id={@workflow_id}
          />
        </div>

        <%!-- Center: Action Buttons --%>
        <div class="flex-1 flex justify-center">
          <.action_buttons
            simulation_run={@simulation_run}
            current_user={@current_user}
            workflow_id={@workflow_id}
            workflow_dirty={@workflow_dirty}
          />
        </div>

        <%!-- Right: View Controls --%>
        <div class="w-64 shrink-0 flex justify-end items-center gap-2">
          <button class="btn btn-sm" phx-click="reset_flow">
            <.icon name="hero-arrow-path" class="w-4 h-4 mr-1" /> Reset
          </button>
          <button class="btn btn-sm" phx-click="fit_view">
            <.icon name="hero-arrows-pointing-out" class="w-4 h-4 mr-1" /> Fit
          </button>
          <button
            class="btn btn-sm btn-info"
            phx-click={JS.dispatch("lf:auto-layout", to: "#eco-workflow-flow")}
          >
            <.icon name="hero-sparkles" class="w-4 h-4 mr-1" /> Auto
          </button>
        </div>
      </div>
    </div>
    """
  end

  # --- Sub-components ---

  defp workflow_name_dropdown(assigns) do
    ~H"""
    <div class="dropdown dropdown-hover">
      <label
        tabindex="0"
        class="btn btn-sm btn-ghost gap-1 text-base font-normal"
        title="Click to rename"
      >
        <span class="truncate max-w-[140px]">{@workflow_name}</span>
        <.status_dot dirty={@workflow_dirty} />
        <.icon name="hero-chevron-down" class="w-3 h-3" />
      </label>
      <ul
        tabindex="0"
        class="dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52"
      >
        <li>
          <a phx-click="open_rename_workflow">
            <.icon name="hero-pencil" class="w-4 h-4" /> Rename
          </a>
        </li>
        <li>
          <a phx-click="open_load_workflow_modal">
            <.icon name="hero-folder-open" class="w-4 h-4" /> Load...
          </a>
        </li>
        <li>
          <a phx-click="reset_to_default">
            <.icon name="hero-arrow-path" class="w-4 h-4" /> Reset to Default
          </a>
        </li>
        <%= if @workflow_id do %>
          <div class="divider my-1"></div>
          <li>
            <a
              phx-click="delete_workflow"
              phx-value-workflow_id={@workflow_id}
              class="text-error"
            >
              <.icon name="hero-trash" class="w-4 h-4" /> Delete
            </a>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  defp status_dot(assigns) do
    ~H"""
    <%= if @dirty do %>
      <span class="w-2 h-2 rounded-full bg-warning"></span>
    <% else %>
      <span class="w-2 h-2 rounded-full bg-success"></span>
    <% end %>
    """
  end

  defp status_indicator(assigns) do
    ~H"""
    <div class="flex items-center gap-2 text-xs">
      <%= if @workflow_saving do %>
        <span class="text-info flex items-center gap-1">
          <span class="loading loading-spinner loading-xs"></span> Saving...
        </span>
      <% else %>
        <%= if @workflow_dirty do %>
          <span class="text-warning">● Unsaved changes</span>
        <% else %>
          <%= if @workflow_id do %>
            <span class="text-success">● Saved</span>
          <% else %>
            <span class="text-base-content/50">● Not saved</span>
          <% end %>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp action_buttons(assigns) do
    ~H"""
    <div class="flex items-center gap-2 bg-base-300/50 px-4 py-2 rounded-xl">
      <button class="btn btn-sm btn-primary" phx-click="add_unit_node">
        <.icon name="hero-plus" class="w-4 h-4 mr-1" /> Add Unit
      </button>

      <%= if @simulation_run do %>
        <button class="btn btn-sm btn-warning" phx-click="clear_simulation">
          <.icon name="hero-arrow-path" class="w-4 h-4 mr-1" /> Reset Simulation
        </button>
      <% else %>
        <button class="btn btn-sm btn-success" phx-click="run_simulation">
          <.icon name="hero-play" class="w-4 h-4 mr-1" /> Run Simulation
        </button>
      <% end %>

      <%= if @current_user do %>
        <div class="w-px h-6 bg-base-content/20 mx-1"></div>
        <%= if @workflow_id do %>
          <button
            class="btn btn-sm btn-info"
            phx-click="quick_save_workflow"
            disabled={not @workflow_dirty}
          >
            <.icon name="hero-document-check" class="w-4 h-4 mr-1" /> Save
          </button>
        <% else %>
          <button class="btn btn-sm btn-info" phx-click="open_save_workflow">
            <.icon name="hero-document-arrow-down" class="w-4 h-4 mr-1" /> Save As
          </button>
        <% end %>
      <% end %>
    </div>
    """
  end
end
