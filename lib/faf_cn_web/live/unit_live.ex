defmodule FafCnWeb.UnitLive do
  @moduledoc """
  LiveView for viewing unit details and comments.
  """
  use FafCnWeb, :live_view

  alias FafCn.Units
  alias FafCn.UnitComments

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

        socket =
          socket
          |> assign(:page_title, unit.name || unit.unit_id)
          |> assign(:unit, unit)
          |> assign(:comments, comments)
          |> assign(:comment_form, to_form(%{"content" => ""}))

        {:ok, socket}
    end
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

        <%!-- Unit Stats --%>
        <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">Economy Stats</h2>
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
        </div>

        <%!-- Comments Section --%>
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
                    <p class="text-gray-700 text-sm whitespace-pre-wrap">
                      {comment.content}
                    </p>

                    <%!-- Delete button (only for owner) --%>
                    <%= if comment.user_id == @current_user.id do %>
                      <button
                        phx-click="delete_comment"
                        phx-value-comment-id={comment.id}
                        class="mt-2 text-xs text-red-600 hover:text-red-800"
                      >
                        Delete
                      </button>
                    <% end %>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>
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
