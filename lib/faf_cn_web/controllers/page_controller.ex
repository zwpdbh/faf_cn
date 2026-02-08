defmodule FafCnWeb.PageController do
  use FafCnWeb, :controller

  def home(conn, _params) do
    render(conn, :home, current_user: conn.assigns[:current_user])
  end

  @doc """
  Silently returns 404 for Chrome DevTools discovery requests.
  This prevents noise in the logs from Chrome browser DevTools.
  """
  def chrome_devtools(conn, _params) do
    conn
    |> put_status(404)
    |> text("")
  end
end
