defmodule FafCnWeb.UnitLive do
  @moduledoc """
  LiveView for viewing unit details.
  """
  use FafCnWeb, :live_view

  alias FafCn.Units

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
        {:ok,
         socket
         |> assign(:page_title, unit.name || unit.unit_id)
         |> assign(:unit, unit)}
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
end
