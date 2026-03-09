defmodule FafCnWeb.EcoWorkflowEditorLive do
  @moduledoc """
  Eco Workflow Editor - Visual economy simulation builder using React Flow.

  This LiveView replaces the previous LiveFlow-based implementation with
  a React Flow-based editor for better performance and user experience.

  ## Flow:
  - :index - Shows list of saved workflows
  - :new - Shows editor with empty/default workflow, prompts for name on save
  - :edit - Loads existing workflow, auto-saves to same workflow
  - :show - Read-only view of workflow
  """
  use FafCnWeb, :live_view

  import FafCnWeb.FafUnitsComponents
  import LiveReact

  alias FafCn.Units
  alias FafCn.EcoWorkflows

  on_mount {FafCnWeb.UserAuth, :mount_current_user}

  @default_engineer_id "UEL0105"
  @t3_engineer_id "UEL0309"
  @t3_pgen_id "UEB1301"
  @t3_mex_id "UEB1302"
  @fatboy_id "UEL0401"

  @impl true
  def mount(_params, _session, socket) do
    # Load default T1 engineer unit
    default_unit = Units.get_unit_by_unit_id(@default_engineer_id)

    # Load available units for selection modal
    units = Units.list_units_for_eco_guides()

    # Load default workflow units
    t3_engineer = Units.get_unit_by_unit_id(@t3_engineer_id)
    t3_pgen = Units.get_unit_by_unit_id(@t3_pgen_id)
    t3_mex = Units.get_unit_by_unit_id(@t3_mex_id)
    fatboy = Units.get_unit_by_unit_id(@fatboy_id)

    workflow_units = %{
      t3_engineer: t3_engineer,
      t3_pgen: t3_pgen,
      t3_mex: t3_mex,
      fatboy: fatboy
    }

    # Create default nodes and edges for React Flow format
    {default_nodes, default_edges} = create_default_workflow_data(workflow_units)

    {:ok,
     socket
     |> assign(:page_title, "Eco Workflow Editor")
     |> assign(:workflow_id, nil)
     |> assign(:workflow_name, "Default Workflow")
     |> assign(:nodes, default_nodes)
     |> assign(:edges, default_edges)
     |> assign(:readonly, false)
     |> assign(:default_unit, default_unit)
     |> assign(:units, units)
     |> assign(:workflow_units, workflow_units)
     |> assign(:selected_node_id, nil)
     |> assign(:selected_edge_id, nil)
     |> assign(:show_unit_selector, false)
     |> assign(:show_save_modal, false)
     |> assign(:show_load_modal, false)
     |> assign(:show_initial_settings, false)
     |> assign(:unsaved_changes, false)
     |> assign(:simulation_run, false)
     |> assign(:save_workflow_error, nil)
     |> assign(:active_filters, [])
     |> assign(:show_eco_only, false)
     |> assign(:selected_faction, "UEF")
     |> assign(:unit_search, "")
     |> assign(:current_unit_id, nil)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    workflows =
      if socket.assigns.current_user do
        EcoWorkflows.list_workflows(socket.assigns.current_user.id)
      else
        []
      end

    socket
    |> assign(:page_title, "Eco Workflows")
    |> assign(:saved_workflows, workflows)
  end

  defp apply_action(socket, :new, _params) do
    {nodes, edges} = create_default_workflow_data(socket.assigns.workflow_units)

    socket
    |> assign(:page_title, "New Eco Workflow")
    |> assign(:workflow_id, nil)
    |> assign(:workflow_name, "Untitled Workflow")
    |> assign(:nodes, nodes)
    |> assign(:edges, edges)
    |> assign(:readonly, false)
    |> assign(:unsaved_changes, true)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    case load_workflow(id, socket.assigns.units) do
      {:ok, %{nodes: nodes, edges: edges, name: name}} ->
        socket
        |> assign(:page_title, name)
        |> assign(:workflow_id, id)
        |> assign(:workflow_name, name)
        |> assign(:nodes, nodes)
        |> assign(:edges, edges)
        |> assign(:readonly, false)
        |> assign(:unsaved_changes, false)

      {:error, _} ->
        socket
        |> put_flash(:error, "Workflow not found")
        |> push_navigate(to: ~p"/eco_workflows")
    end
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    case load_workflow(id, socket.assigns.units) do
      {:ok, %{nodes: nodes, edges: edges, name: name}} ->
        socket
        |> assign(:page_title, name)
        |> assign(:workflow_id, id)
        |> assign(:workflow_name, name)
        |> assign(:nodes, nodes)
        |> assign(:edges, edges)
        |> assign(:readonly, true)
        |> assign(:unsaved_changes, false)

      {:error, _} ->
        socket
        |> put_flash(:error, "Workflow not found")
        |> push_navigate(to: ~p"/eco_workflows")
    end
  end

  # ===== Render =====

  @impl true
  def render(%{live_action: :index} = assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="max-w-6xl mx-auto px-6 py-8">
        <div class="flex items-center justify-between mb-8">
          <div>
            <h1 class="text-3xl font-bold">Eco Workflows</h1>
            <p class="text-base-content/60 mt-1">Design and simulate your economy builds</p>
          </div>
          <.link navigate={~p"/eco_workflows/new"} class="btn btn-primary">
            <.icon name="hero-plus" class="w-5 h-5 mr-2" /> New Workflow
          </.link>
        </div>

        <div class="grid gap-4">
          <%= if Enum.empty?(@saved_workflows) do %>
            <div class="text-center py-16 bg-base-200 rounded-lg">
              <.icon name="hero-cube" class="w-12 h-12 mx-auto text-base-content/30 mb-4" />
              <p class="text-base-content/60">No workflows yet</p>
              <.link navigate={~p"/eco_workflows/new"} class="btn btn-sm btn-primary mt-4">
                Create your first workflow
              </.link>
            </div>
          <% else %>
            <%= for workflow <- @saved_workflows do %>
              <div class="bg-base-100 border border-base-300 rounded-lg p-4 flex items-center justify-between hover:shadow-md transition-shadow">
                <div>
                  <h3 class="font-semibold text-lg">{workflow.name}</h3>
                  <div class="flex gap-2 mt-2">
                    <span class="text-xs text-base-content/40">
                      Updated {Calendar.strftime(workflow.updated_at, "%Y-%m-%d %H:%M")}
                    </span>
                  </div>
                </div>
                <div class="flex gap-2">
                  <.link navigate={~p"/eco_workflows/#{workflow.id}"} class="btn btn-ghost btn-sm">
                    <.icon name="hero-eye" class="w-4 h-4" />
                  </.link>
                  <.link
                    navigate={~p"/eco_workflows/#{workflow.id}/edit"}
                    class="btn btn-primary btn-sm"
                  >
                    <.icon name="hero-pencil" class="w-4 h-4" />
                  </.link>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def render(%{live_action: action} = assigns) when action in [:new, :edit, :show] do
    ~H"""
    <Layouts.fullscreen flash={@flash}>
      <%!-- Workflow Editor - Full screen with React Flow --%>
      <div class="relative h-screen w-screen">
        <.react
          name="WorkflowEditor"
          initialNodes={@nodes}
          initialEdges={@edges}
          readonly={@readonly}
          workflowId={@workflow_id}
          workflowName={@workflow_name}
          class="w-full h-full"
        />

        <%!-- Unit Selector Modal --%>
        <%= if @show_unit_selector do %>
          <.unit_selector_modal
            show={true}
            units_by_faction={group_units_by_faction(@units)}
            selected_faction={@selected_faction}
            current_unit_id={@current_unit_id}
            active_filters={@active_filters}
            show_eco_only={@show_eco_only}
          />
        <% end %>
      </div>
    </Layouts.fullscreen>
    """
  end

  # ===== Event Handlers from React Flow =====

  @impl true
  def handle_event("node_clicked", %{"nodeId" => node_id, "data" => _data}, socket) do
    {:noreply,
     socket
     |> assign(:selected_node_id, node_id)
     |> assign(:selected_edge_id, nil)}
  end

  @impl true
  def handle_event("edge_clicked", %{"edgeId" => edge_id, "edge" => _edge}, socket) do
    {:noreply,
     socket
     |> assign(:selected_edge_id, edge_id)
     |> assign(:selected_node_id, nil)}
  end

  @impl true
  def handle_event("node_added", %{"node" => node}, socket) do
    {:noreply,
     socket
     |> update(:nodes, fn nodes -> [convert_to_react_flow_node(node) | nodes] end)
     |> assign(:unsaved_changes, true)}
  end

  @impl true
  def handle_event("node_deleted", %{"nodeId" => node_id}, socket) do
    {:noreply,
     socket
     |> update(:nodes, fn nodes -> Enum.reject(nodes, &(&1["id"] == node_id)) end)
     |> assign(:selected_node_id, nil)
     |> assign(:unsaved_changes, true)}
  end

  @impl true
  def handle_event("edge_created", %{"connection" => _connection}, socket) do
    {:noreply, assign(socket, :unsaved_changes, true)}
  end

  @impl true
  def handle_event("edge_deleted", %{"edgeId" => edge_id}, socket) do
    {:noreply,
     socket
     |> update(:edges, fn edges -> Enum.reject(edges, &(&1["id"] == edge_id)) end)
     |> assign(:selected_edge_id, nil)
     |> assign(:unsaved_changes, true)}
  end

  @impl true
  def handle_event("node_updated", %{"nodeId" => node_id, "data" => data}, socket) do
    {:noreply,
     socket
     |> update(:nodes, fn nodes ->
       Enum.map(nodes, fn node ->
         if node["id"] == node_id do
           put_in(node, ["data"], Map.merge(node["data"], data))
         else
           node
         end
       end)
     end)
     |> assign(:unsaved_changes, true)}
  end

  @impl true
  def handle_event("workflow_cleared", _params, socket) do
    initial_node = Enum.find(socket.assigns.nodes, &(&1["data"]["type"] == "initial"))

    {:noreply,
     socket
     |> assign(:nodes, if(initial_node, do: [initial_node], else: []))
     |> assign(:edges, [])
     |> assign(:selected_node_id, nil)
     |> assign(:selected_edge_id, nil)
     |> assign(:unsaved_changes, true)}
  end

  @impl true
  def handle_event("workflow_reset", _params, socket) do
    {nodes, edges} = create_default_workflow_data(socket.assigns.workflow_units)

    {:noreply,
     socket
     |> assign(:nodes, nodes)
     |> assign(:edges, edges)
     |> assign(:selected_node_id, nil)
     |> assign(:selected_edge_id, nil)
     |> assign(:unsaved_changes, true)
     |> assign(:simulation_run, false)}
  end

  @impl true
  def handle_event("run_simulation", %{"nodes" => nodes, "edges" => edges}, socket) do
    # Convert React Flow format to simulation format and run
    # This is a placeholder - implement actual simulation logic
    require Logger
    Logger.debug("Running simulation with #{length(nodes)} nodes and #{length(edges)} edges")

    # TODO: Implement simulation using existing eco engine
    {:noreply,
     socket
     |> assign(:simulation_run, true)
     |> put_flash(:info, "Simulation started")}
  end

  @impl true
  def handle_event("auto_save", %{"nodes" => nodes, "edges" => edges}, socket) do
    workflow_id = socket.assigns.workflow_id

    if workflow_id && socket.assigns.current_user do
      user_id = socket.assigns.current_user.id

      # Convert to internal format and save
      attrs = %{
        "name" => socket.assigns.workflow_name,
        "user_id" => user_id,
        "nodes" => convert_nodes_to_db_format(nodes),
        "edges" => convert_edges_to_db_format(edges)
      }

      case EcoWorkflows.update_workflow_with_graph(workflow_id, attrs) do
        {:ok, _} ->
          {:noreply, assign(socket, :unsaved_changes, false)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Auto-save failed")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("save_workflow", _params, socket) do
    workflow_id = socket.assigns.workflow_id

    cond do
      is_nil(socket.assigns.current_user) ->
        {:noreply,
         socket
         |> put_flash(:info, "Please log in to save workflows")
         |> push_navigate(to: ~p"/auth/github")}

      is_nil(workflow_id) ->
        # New workflow - show save modal
        {:noreply, assign(socket, :show_save_modal, true)}

      true ->
        # Existing workflow - save directly
        handle_save_workflow(socket, socket.assigns.workflow_name)
    end
  end

  @impl true
  def handle_event("save_workflow_as", _params, socket) do
    {:noreply, assign(socket, :show_save_modal, true)}
  end

  @impl true
  def handle_event("load_workflow", _params, socket) do
    workflows =
      if socket.assigns.current_user do
        EcoWorkflows.list_workflows(socket.assigns.current_user.id)
      else
        []
      end

    {:noreply, assign(socket, show_load_modal: true, saved_workflows: workflows)}
  end

  @impl true
  def handle_event("open_unit_selector", %{"nodeId" => node_id}, socket) do
    node = Enum.find(socket.assigns.nodes, &(&1["id"] == node_id))
    current_unit_id = node && get_in(node, ["data", "unit", "unit_id"])

    {:noreply,
     assign(socket,
       show_unit_selector: true,
       selected_node_id: node_id,
       current_unit_id: current_unit_id,
       selected_faction: "UEF",
       unit_search: "",
       active_filters: [],
       show_eco_only: false
     )}
  end

  @impl true
  def handle_event("close_unit_selector", _params, socket) do
    {:noreply,
     assign(socket,
       show_unit_selector: false,
       selected_node_id: nil,
       current_unit_id: nil
     )}
  end

  @impl true
  def handle_event("select_unit_for_node", %{"unit_id" => unit_id}, socket) do
    node_id = socket.assigns.selected_node_id
    unit = Enum.find(socket.assigns.units, &(&1.unit_id == unit_id))

    if unit && node_id do
      {:noreply,
       socket
       |> update(:nodes, fn nodes ->
         Enum.map(nodes, fn node ->
           if node["id"] == node_id do
             put_in(
               node,
               ["data"],
               Map.merge(node["data"], %{
                 "unit" => unit_to_json(unit),
                 "label" => unit.name
               })
             )
           else
             node
           end
         end)
       end)
       |> assign(:show_unit_selector, false)
       |> assign(:unsaved_changes, true)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("select_faction", %{"faction" => faction}, socket) do
    {:noreply, assign(socket, selected_faction: faction)}
  end

  @impl true
  def handle_event("toggle_eco_filter", _params, socket) do
    {:noreply, assign(socket, show_eco_only: !socket.assigns.show_eco_only)}
  end

  @impl true
  def handle_event("toggle_filter", %{"filter" => filter_key}, socket) do
    # Handle filter toggling similar to original implementation
    active_filters = socket.assigns.active_filters

    new_filters =
      if filter_key in active_filters do
        List.delete(active_filters, filter_key)
      else
        active_filters ++ [filter_key]
      end

    {:noreply, assign(socket, active_filters: new_filters)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply, assign(socket, active_filters: [], show_eco_only: false)}
  end

  @impl true
  def handle_event("search_units", %{"value" => search}, socket) do
    {:noreply, assign(socket, unit_search: search)}
  end

  @impl true
  def handle_event("history_undo", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("history_redo", _params, socket) do
    {:noreply, socket}
  end

  # ===== Private Functions =====

  defp create_default_workflow_data(workflow_units) do
    initial_node = %{
      "id" => "initial",
      "type" => "default",
      "position" => %{"x" => 50, "y" => 200},
      "data" => %{
        "label" => "Initial Eco",
        "type" => "initial",
        "status" => "idle",
        "mass_in_storage" => 650,
        "energy_in_storage" => 5000,
        "mass_per_sec" => 1.0,
        "energy_per_sec" => 20.0,
        "build_power" => 10
      }
    }

    required_units = [
      workflow_units[:t3_engineer],
      workflow_units[:t3_pgen],
      workflow_units[:t3_mex],
      workflow_units[:fatboy]
    ]

    if Enum.any?(required_units, &is_nil/1) do
      {[initial_node], []}
    else
      unit_nodes = [
        %{
          "id" => "unit-t3-eng-1",
          "type" => "default",
          "position" => %{"x" => 250, "y" => 100},
          "data" => %{
            "label" => "T3 Engineer",
            "type" => "unit",
            "status" => "idle",
            "unit" => unit_to_json(workflow_units[:t3_engineer]),
            "quantity" => 1
          }
        },
        %{
          "id" => "unit-t3-eng-2",
          "type" => "default",
          "position" => %{"x" => 400, "y" => 200},
          "data" => %{
            "label" => "T3 Engineer",
            "type" => "unit",
            "status" => "idle",
            "unit" => unit_to_json(workflow_units[:t3_engineer]),
            "quantity" => 1
          }
        },
        %{
          "id" => "unit-t3-eng-3",
          "type" => "default",
          "position" => %{"x" => 550, "y" => 300},
          "data" => %{
            "label" => "T3 Engineer",
            "type" => "unit",
            "status" => "idle",
            "unit" => unit_to_json(workflow_units[:t3_engineer]),
            "quantity" => 1
          }
        },
        %{
          "id" => "unit-t3-pgen",
          "type" => "default",
          "position" => %{"x" => 700, "y" => 200},
          "data" => %{
            "label" => "T3 Power Generator",
            "type" => "unit",
            "status" => "idle",
            "unit" => unit_to_json(workflow_units[:t3_pgen]),
            "quantity" => 1
          }
        },
        %{
          "id" => "unit-t3-mex",
          "type" => "default",
          "position" => %{"x" => 850, "y" => 200},
          "data" => %{
            "label" => "T3 Mass Extractor",
            "type" => "unit",
            "status" => "idle",
            "unit" => unit_to_json(workflow_units[:t3_mex]),
            "quantity" => 1
          }
        },
        %{
          "id" => "unit-fatboy",
          "type" => "default",
          "position" => %{"x" => 1000, "y" => 200},
          "data" => %{
            "label" => "Fatboy",
            "type" => "unit",
            "status" => "idle",
            "unit" => unit_to_json(workflow_units[:fatboy]),
            "quantity" => 1
          }
        }
      ]

      edges = [
        %{
          "id" => "e-initial",
          "source" => "initial",
          "target" => "unit-t3-eng-1",
          "animated" => false
        },
        %{
          "id" => "e-eng-1",
          "source" => "unit-t3-eng-1",
          "target" => "unit-t3-eng-2",
          "animated" => false
        },
        %{
          "id" => "e-eng-2",
          "source" => "unit-t3-eng-2",
          "target" => "unit-t3-eng-3",
          "animated" => false
        },
        %{
          "id" => "e-eng-3",
          "source" => "unit-t3-eng-3",
          "target" => "unit-t3-pgen",
          "animated" => false
        },
        %{
          "id" => "e-pgen",
          "source" => "unit-t3-pgen",
          "target" => "unit-t3-mex",
          "animated" => false
        },
        %{
          "id" => "e-mex",
          "source" => "unit-t3-mex",
          "target" => "unit-fatboy",
          "animated" => false
        }
      ]

      {[initial_node | unit_nodes], edges}
    end
  end

  defp unit_to_json(unit) when is_struct(unit) do
    %{
      "unit_id" => unit.unit_id,
      "name" => unit.name || unit.description || unit.unit_id,
      "faction" => unit.faction,
      "tech_level" => extract_tech_level(unit.categories),
      "mass_cost" => unit.build_cost_mass,
      "energy_cost" => unit.build_cost_energy,
      "build_time" => unit.build_time
    }
  end

  defp unit_to_json(unit), do: unit

  defp extract_tech_level(categories) when is_list(categories) do
    cond do
      "TECH4" in categories -> 4
      "TECH3" in categories -> 3
      "TECH2" in categories -> 2
      "TECH1" in categories -> 1
      true -> 1
    end
  end

  defp extract_tech_level(_), do: 1

  defp convert_to_react_flow_node(node) when is_map(node) do
    %{
      "id" => node["id"],
      "type" => node["type"] || "default",
      "position" => node["position"] || %{"x" => 0, "y" => 0},
      "data" => node["data"] || %{}
    }
  end

  defp convert_nodes_to_db_format(nodes) do
    Enum.map(nodes, fn node ->
      data = node["data"] || %{}
      unit = data["unit"]

      %{
        "node_id" => node["id"],
        "node_type" => data["type"] || "unit",
        "unit_id" => unit && unit["unit_id"],
        "quantity" => data["quantity"] || 1,
        "pos_x" => get_in(node, ["position", "x"]) || 0,
        "pos_y" => get_in(node, ["position", "y"]) || 0
      }
    end)
  end

  defp convert_edges_to_db_format(edges) do
    Enum.map(edges, fn edge ->
      %{
        "edge_id" => edge["id"],
        "source_node_id" => edge["source"],
        "target_node_id" => edge["target"]
      }
    end)
  end

  defp load_workflow(id, available_units) do
    case EcoWorkflows.get_workflow(id) do
      nil -> {:error, :not_found}
      workflow -> build_workflow_data(workflow, available_units)
    end
  end

  defp build_workflow_data(workflow, available_units) do
    units_by_id = build_unit_lookup_map(available_units)
    nodes = convert_nodes_to_react_flow(workflow.nodes, units_by_id)
    nodes = ensure_initial_node(nodes)
    edges = convert_edges_to_react_flow(workflow.edges)

    {:ok, %{nodes: nodes, edges: edges, name: workflow.name}}
  end

  defp build_unit_lookup_map(units) do
    Map.new(units, &{&1.unit_id, &1})
  end

  defp convert_nodes_to_react_flow(db_nodes, units_by_id) do
    Enum.map(db_nodes, &convert_node_to_react_flow(&1, units_by_id))
  end

  defp convert_node_to_react_flow(db_node, units_by_id) do
    unit = db_node.unit_id && Map.get(units_by_id, db_node.unit_id)

    %{
      "id" => db_node.node_id,
      "type" => "default",
      "position" => %{"x" => db_node.pos_x || 0, "y" => db_node.pos_y || 0},
      "data" => %{
        "label" => if(unit, do: unit.name, else: "Unit"),
        "type" => db_node.node_type || "unit",
        "status" => "idle",
        "unit" => unit && unit_to_json(unit),
        "quantity" => db_node.quantity || 1
      }
    }
  end

  defp ensure_initial_node(nodes) do
    if Enum.any?(nodes, &(get_in(&1, ["data", "type"]) == "initial")) do
      nodes
    else
      [create_initial_node() | nodes]
    end
  end

  defp convert_edges_to_react_flow(db_edges) do
    Enum.map(db_edges, fn db_edge ->
      %{
        "id" => db_edge.edge_id,
        "source" => db_edge.source_node_id,
        "target" => db_edge.target_node_id,
        "animated" => false
      }
    end)
  end

  defp create_initial_node do
    %{
      "id" => "initial",
      "type" => "default",
      "position" => %{"x" => 50, "y" => 200},
      "data" => %{
        "label" => "Initial Eco",
        "type" => "initial",
        "status" => "idle",
        "mass_in_storage" => 650,
        "energy_in_storage" => 5000,
        "mass_per_sec" => 1.0,
        "energy_per_sec" => 20.0,
        "build_power" => 10
      }
    }
  end

  defp handle_save_workflow(socket, name) do
    nodes = socket.assigns.nodes
    edges = socket.assigns.edges
    user_id = socket.assigns.current_user.id

    attrs = %{
      "name" => name,
      "user_id" => user_id,
      "nodes" => convert_nodes_to_db_format(nodes),
      "edges" => convert_edges_to_db_format(edges)
    }

    workflow_id = socket.assigns.workflow_id

    result =
      if workflow_id do
        EcoWorkflows.update_workflow_with_graph(workflow_id, attrs)
      else
        EcoWorkflows.create_workflow_with_graph(attrs)
      end

    case result do
      {:ok, workflow} ->
        {:noreply,
         socket
         |> assign(:workflow_id, workflow.id)
         |> assign(:workflow_name, workflow.name)
         |> assign(:unsaved_changes, false)
         |> assign(:show_save_modal, false)
         |> put_flash(:info, "Workflow saved successfully")}

      {:error, changeset} ->
        error =
          case changeset.errors[:name] do
            {msg, _} -> "Name #{msg}"
            _ -> "Failed to save workflow"
          end

        {:noreply,
         socket
         |> assign(:save_workflow_error, error)}
    end
  end

  defp group_units_by_faction(units) do
    Enum.group_by(units, & &1.faction)
  end
end
