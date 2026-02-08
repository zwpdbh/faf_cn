defmodule FafCnWeb.UnitLive do
  @moduledoc """
  LiveView for viewing unit details, comments, and admin editing.
  """
  use FafCnWeb, :live_view

  alias FafCn.Units
  alias FafCn.UnitComments
  alias FafCn.UnitEditLogs
  alias FafCn.Accounts

  on_mount {FafCnWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(%{"unit_id" => unit_id}, _session, socket) do
    case Units.get_unit_by_unit_id(unit_id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Unit not found")
         |> push_navigate(to: ~p"/")}

      unit ->
        comments = UnitComments.list_unit_comments(unit.id)
        edit_logs = UnitEditLogs.list_unit_edit_logs(unit.id)
        is_admin = Accounts.is_admin?(socket.assigns.current_user)

        socket =
          socket
          |> assign(:page_title, unit.name || unit.unit_id)
          |> assign(:unit, unit)
          |> assign(:comments, comments)
          |> assign(:edit_logs, edit_logs)
          |> assign(:is_admin, is_admin)
          |> assign(:edit_mode, false)
          |> assign(:editing_comment_id, nil)
          |> assign(:comment_form, to_form(%{"content" => ""}))
          |> assign(
            :edit_form,
            to_form(%{
              "mass" => unit.build_cost_mass,
              "energy" => unit.build_cost_energy,
              "build_time" => unit.build_time,
              "reason" => ""
            })
          )
          |> assign(:edit_error, nil)

        {:ok, socket}
    end
  end

  @impl true
  def handle_event("toggle_edit_mode", _params, socket) do
    {:noreply, assign(socket, :edit_mode, !socket.assigns.edit_mode)}
  end

  @impl true
  def handle_event("cancel_edit", _params, socket) do
    unit = socket.assigns.unit

    {:noreply,
     socket
     |> assign(:edit_mode, false)
     |> assign(
       :edit_form,
       to_form(%{
         "mass" => unit.build_cost_mass,
         "energy" => unit.build_cost_energy,
         "build_time" => unit.build_time,
         "reason" => ""
       })
     )
     |> assign(:edit_error, nil)}
  end

  @impl true
  def handle_event("add_comment", %{"content" => content}, socket) do
    unit = socket.assigns.unit
    user = socket.assigns.current_user

    case UnitComments.create_comment(unit.id, user.id, content) do
      {:ok, _comment} ->
        comments = UnitComments.list_unit_comments(unit.id)

        {:noreply,
         socket
         |> assign(:comments, comments)
         |> assign(:comment_form, to_form(%{"content" => ""}))
         |> put_flash(:info, "Comment added")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to add comment")}
    end
  end

  @impl true
  def handle_event("delete_comment", %{"comment-id" => comment_id}, socket) do
    user = socket.assigns.current_user

    case UnitComments.delete_comment(String.to_integer(comment_id), user.id) do
      :ok ->
        comments = UnitComments.list_unit_comments(socket.assigns.unit.id)
        {:noreply, assign(socket, :comments, comments)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete comment")}
    end
  end

  @impl true
  def handle_event("edit_comment", %{"comment-id" => comment_id}, socket) do
    {:noreply, assign(socket, :editing_comment_id, String.to_integer(comment_id))}
  end

  @impl true
  def handle_event("cancel_edit_comment", _params, socket) do
    {:noreply, assign(socket, :editing_comment_id, nil)}
  end

  @impl true
  def handle_event(
        "save_comment_edit",
        %{"comment-id" => comment_id, "content" => content},
        socket
      ) do
    user = socket.assigns.current_user

    case UnitComments.update_comment(String.to_integer(comment_id), user.id, content) do
      {:ok, _comment} ->
        comments = UnitComments.list_unit_comments(socket.assigns.unit.id)

        {:noreply,
         socket
         |> assign(:comments, comments)
         |> assign(:editing_comment_id, nil)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update comment")}
    end
  end

  @impl true
  def handle_event("update_stats", params, socket) do
    unit = socket.assigns.unit
    user = socket.assigns.current_user

    mass = params["mass"]
    energy = params["energy"]
    build_time = params["build_time"]
    reason = params["reason"]

    if reason == nil or String.trim(reason) == "" do
      {:noreply, assign(socket, :edit_error, "Reason is required for all edits")}
    else
      case UnitEditLogs.update_unit_stat(unit, "build_cost_mass", mass, reason, user.id) do
        {:ok, updated_unit} ->
          case UnitEditLogs.update_unit_stat(
                 updated_unit,
                 "build_cost_energy",
                 energy,
                 reason,
                 user.id
               ) do
            {:ok, updated_unit2} ->
              case UnitEditLogs.update_unit_stat(
                     updated_unit2,
                     "build_time",
                     build_time,
                     reason,
                     user.id
                   ) do
                {:ok, final_unit} ->
                  edit_logs = UnitEditLogs.list_unit_edit_logs(unit.id)

                  {:noreply,
                   socket
                   |> assign(:unit, final_unit)
                   |> assign(:edit_logs, edit_logs)
                   |> assign(:edit_mode, false)
                   |> assign(
                     :edit_form,
                     to_form(%{
                       "mass" => final_unit.build_cost_mass,
                       "energy" => final_unit.build_cost_energy,
                       "build_time" => final_unit.build_time,
                       "reason" => ""
                     })
                   )
                   |> assign(:edit_error, nil)
                   |> put_flash(:info, "Unit stats updated")}

                {:error, changeset} ->
                  {:noreply, assign(socket, :edit_error, error_message(changeset))}
              end

            {:error, changeset} ->
              {:noreply, assign(socket, :edit_error, error_message(changeset))}
          end

        {:error, "Unauthorized"} ->
          {:noreply, put_flash(socket, :error, "You are not authorized to edit units")}

        {:error, changeset} ->
          {:noreply, assign(socket, :edit_error, error_message(changeset))}
      end
    end
  end

  defp error_message(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%\{(\w+)\}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map(fn {k, v} -> "#{k}: #{Enum.join(v, ", ")}" end)
    |> Enum.join("; ")
  end

  defp error_message(msg) when is_binary(msg), do: msg
  defp error_message(_), do: "An error occurred"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <%!-- Back link --%>
        <a
          href={~p"/eco-guides"}
          class="text-indigo-600 hover:text-indigo-800 mb-4 inline-flex items-center"
        >
          <.icon name="hero-arrow-left" class="w-4 h-4 mr-1" /> Back to Eco Guides
        </a>

        <%!-- Unit Header --%>
        <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
          <div class="flex items-start gap-6">
            <%!-- Large Unit Icon --%>
            <div class={[
              "w-24 h-24 rounded-xl flex items-center justify-center flex-shrink-0",
              unit_faction_bg_class(@unit.faction)
            ]}>
              <div class={"unit-icon-#{@unit.unit_id} w-20 h-20"}></div>
            </div>

            <%!-- Unit Info --%>
            <div class="flex-1">
              <div class="flex items-center gap-3 mb-2">
                <span class="text-sm font-medium text-gray-500">{@unit.unit_id}</span>
                <span class={[
                  "px-2 py-0.5 rounded text-xs font-medium",
                  case @unit.faction do
                    "UEF" -> "bg-blue-100 text-blue-800"
                    "CYBRAN" -> "bg-red-100 text-red-800"
                    "AEON" -> "bg-emerald-100 text-emerald-800"
                    "SERAPHIM" -> "bg-violet-100 text-violet-800"
                    _ -> "bg-gray-100 text-gray-800"
                  end
                ]}>
                  {@unit.faction}
                </span>
              </div>
              <h1 class="text-2xl font-bold text-gray-900 mb-2">
                {@unit.name || @unit.unit_id}
              </h1>
              <p class="text-gray-600">
                {@unit.description || "No description available"}
              </p>
            </div>
          </div>
        </div>

        <%!-- Unit Stats Card --%>
        <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-lg font-semibold text-gray-900">Economy Stats</h2>
            <%= if @is_admin and not @edit_mode do %>
              <button
                phx-click="toggle_edit_mode"
                class="inline-flex items-center px-3 py-1.5 text-sm font-medium text-indigo-600 bg-indigo-50 hover:bg-indigo-100 rounded-md transition-colors"
              >
                <.icon name="hero-pencil-square" class="w-4 h-4 mr-1.5" /> Edit
              </button>
            <% end %>
          </div>

          <%= if @edit_mode do %>
            <%!-- Edit Form --%>
            <%= if @edit_error do %>
              <div class="mb-4 p-3 bg-red-50 border border-red-200 rounded-md text-red-700 text-sm">
                {@edit_error}
              </div>
            <% end %>

            <.form
              for={@edit_form}
              id="edit-stats-form"
              phx-submit="update_stats"
              class="space-y-4"
            >
              <div class="grid grid-cols-3 gap-4">
                <div>
                  <label for="mass" class="block text-sm font-medium text-gray-700 mb-1">Mass</label>
                  <input
                    type="number"
                    name="mass"
                    id="mass"
                    value={@edit_form[:mass].value}
                    class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                    required
                  />
                </div>
                <div>
                  <label for="energy" class="block text-sm font-medium text-gray-700 mb-1">
                    Energy
                  </label>
                  <input
                    type="number"
                    name="energy"
                    id="energy"
                    value={@edit_form[:energy].value}
                    class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                    required
                  />
                </div>
                <div>
                  <label for="build_time" class="block text-sm font-medium text-gray-700 mb-1">
                    Build Time
                  </label>
                  <input
                    type="number"
                    name="build_time"
                    id="build_time"
                    value={@edit_form[:build_time].value}
                    class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                    required
                  />
                </div>
              </div>

              <div>
                <label for="reason" class="block text-sm font-medium text-gray-700 mb-1">
                  Reason for Edit <span class="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  name="reason"
                  id="reason"
                  value={@edit_form[:reason].value}
                  placeholder="e.g., Balance update, Data correction"
                  class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                  required
                />
              </div>

              <div class="flex justify-end gap-3">
                <button
                  type="button"
                  phx-click="cancel_edit"
                  class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  Update Stats
                </button>
              </div>
            </.form>
          <% else %>
            <%!-- Stats Display --%>
            <div class="grid grid-cols-3 gap-4">
              <div class="text-center p-4 bg-gray-50 rounded-lg">
                <div class="text-sm text-gray-500 mb-1">Mass</div>
                <div class="text-2xl font-bold text-gray-900">
                  {format_number(@unit.build_cost_mass)}
                </div>
              </div>
              <div class="text-center p-4 bg-gray-50 rounded-lg">
                <div class="text-sm text-gray-500 mb-1">Energy</div>
                <div class="text-2xl font-bold text-gray-900">
                  {format_number(@unit.build_cost_energy)}
                </div>
              </div>
              <div class="text-center p-4 bg-gray-50 rounded-lg">
                <div class="text-sm text-gray-500 mb-1">Build Time</div>
                <div class="text-2xl font-bold text-gray-900">
                  {format_number(@unit.build_time)}
                </div>
              </div>
            </div>
          <% end %>
        </div>

        <%!-- Edit History (only show when in edit mode) --%>
        <%= if @edit_mode and @edit_logs != [] do %>
          <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
            <h2 class="text-lg font-semibold text-gray-900 mb-4">Edit History</h2>
            <div class="space-y-3">
              <%= for log <- @edit_logs do %>
                <div class="flex items-center gap-4 p-3 bg-gray-50 rounded-lg text-sm">
                  <div class="flex-1">
                    <span class="font-medium text-gray-900">{log.field}</span>
                    <span class="text-gray-500"> changed from </span>
                    <span class="font-medium text-red-600">{log.old_value}</span>
                    <span class="text-gray-500"> to </span>
                    <span class="font-medium text-green-600">{log.new_value}</span>
                  </div>
                  <div class="text-right">
                    <div class="text-gray-700">{log.reason}</div>
                    <div class="text-xs text-gray-500">
                      by {log.editor.name || log.editor.email} · {format_timestamp(log.inserted_at)}
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>

        <%!-- Comments Section (hidden when in edit mode) --%>
        <%= if not @edit_mode do %>
          <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <h2 class="text-lg font-semibold text-gray-900 mb-4">
              Comments ({length(@comments)})
            </h2>

            <%!-- Comment Form --%>
            <.form
              for={@comment_form}
              id="comment-form"
              phx-submit="add_comment"
              class="mb-6"
            >
              <div class="flex gap-3">
                <textarea
                  name="content"
                  rows="2"
                  placeholder="Add a comment..."
                  class="flex-1 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                  required
                ></textarea>
                <button
                  type="submit"
                  class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  Post
                </button>
              </div>
            </.form>

            <%!-- Comments List --%>
            <div class="space-y-4">
              <%= if @comments == [] do %>
                <p class="text-center text-gray-500 py-4">
                  No comments yet. Be the first to share your thoughts!
                </p>
              <% else %>
                <%= for comment <- @comments do %>
                  <div class="flex gap-3 p-4 bg-gray-50 rounded-lg">
                    <%!-- Avatar --%>
                    <div class="flex-shrink-0">
                      <%= if comment.user.avatar_url do %>
                        <img
                          src={comment.user.avatar_url}
                          alt={comment.user.name}
                          class="w-10 h-10 rounded-full"
                        />
                      <% else %>
                        <div class="w-10 h-10 rounded-full bg-gray-300 flex items-center justify-center">
                          <.icon name="hero-user" class="w-6 h-6 text-gray-500" />
                        </div>
                      <% end %>
                    </div>

                    <%!-- Comment Content --%>
                    <div class="flex-1 min-w-0">
                      <div class="flex items-center justify-between mb-1">
                        <span class="font-medium text-gray-900">
                          {comment.user.name || comment.user.email}
                        </span>
                        <span class="text-xs text-gray-500">
                          {format_timestamp(comment.inserted_at)}
                        </span>
                      </div>

                      <%!-- Edit form (when editing this comment) --%>
                      <%= if @editing_comment_id == comment.id do %>
                        <form phx-submit="save_comment_edit" class="mb-2">
                          <input type="hidden" name="comment-id" value={comment.id} />
                          <textarea
                            name="content"
                            rows="2"
                            class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm mb-2"
                            required
                          >{comment.content}</textarea>
                          <div class="flex gap-2">
                            <button
                              type="button"
                              phx-click="cancel_edit_comment"
                              class="text-xs text-gray-600 hover:text-gray-800"
                            >
                              Cancel
                            </button>
                            <button
                              type="submit"
                              class="text-xs text-indigo-600 hover:text-indigo-800 font-medium"
                            >
                              Save
                            </button>
                          </div>
                        </form>
                      <% else %>
                        <p class="text-gray-700 text-sm whitespace-pre-wrap">
                          {comment.content}
                        </p>

                        <%!-- Edit/Delete buttons (only for owner) --%>
                        <%= if comment.user_id == @current_user.id do %>
                          <div class="flex gap-3 mt-2">
                            <button
                              phx-click="edit_comment"
                              phx-value-comment-id={comment.id}
                              class="text-xs text-indigo-600 hover:text-indigo-800"
                            >
                              Edit
                            </button>
                            <button
                              phx-click="delete_comment"
                              phx-value-comment-id={comment.id}
                              class="text-xs text-red-600 hover:text-red-800"
                            >
                              Delete
                            </button>
                          </div>
                        <% end %>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  defp unit_faction_bg_class(faction) do
    case faction do
      "UEF" -> "unit-bg-uef"
      "CYBRAN" -> "unit-bg-cybran"
      "AEON" -> "unit-bg-aeon"
      "SERAPHIM" -> "unit-bg-seraphim"
      _ -> "unit-bg-uef"
    end
  end

  defp format_number(nil), do: "0"
  defp format_number(n) when n < 1000, do: to_string(n)

  defp format_number(n) do
    n
    |> to_string()
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end

  defp format_timestamp(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      diff < 604_800 -> "#{div(diff, 86400)}d ago"
      true -> Calendar.strftime(datetime, "%Y-%m-%d")
    end
  end
end
