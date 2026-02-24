defmodule FafCnWeb.EcoWorkflow.MassRateNode do
  @moduledoc """
  Mass Rate Node - Shows mass income, drain, and net production rate.
  """
  use Phoenix.LiveComponent
  import FafCnWeb.CoreComponents

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    income = Map.get(assigns.node.data, :income, 0)
    drain = Map.get(assigns.node.data, :drain, 0)
    net = Map.get(assigns.node.data, :net, income - drain)
    net_positive = net >= 0

    assigns =
      assigns
      |> assign(income: income, drain: drain, net: net, net_positive: net_positive)

    ~H"""
    <div class="workflow-node">
      <div class="workflow-node-header workflow-node-mass">
        <.icon name="hero-arrow-trending-up" class="w-4 h-4" />
        <span>{@node.data[:label] || "Mass Rate"}</span>
      </div>
      <div class="workflow-node-body">
        <div class="flex justify-between text-xs mb-1">
          <span class="text-success">+{@income}</span>
          <span class="text-error">-{@drain}</span>
        </div>
        <div class={[
          "workflow-node-value text-center",
          if(@net_positive, do: "text-mass", else: "text-error")
        ]}>
          {if(@net_positive, do: "+", else: "")}{@net}
        </div>
        <div class="workflow-node-unit text-center">{@node.data[:unit]}</div>
      </div>
    </div>
    """
  end
end
