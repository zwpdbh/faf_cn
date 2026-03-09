defmodule FafCnWeb.RedirectController do
  use FafCnWeb, :controller

  def eco_workflow(conn, _params) do
    redirect(conn, to: ~p"/eco_workflows")
  end
end
