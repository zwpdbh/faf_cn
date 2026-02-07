defmodule FafCnWeb.PageController do
  use FafCnWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
