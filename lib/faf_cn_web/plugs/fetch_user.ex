defmodule FafCnWeb.Plugs.FetchUser do
  @moduledoc """
  Plug to fetch the current user from the session.
  """
  import Plug.Conn

  alias FafCn.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)

    if is_integer(user_id) do
      case Accounts.get_user(user_id) do
        nil ->
          # User was deleted, clear session
          delete_session(conn, :user_id)

        user ->
          assign(conn, :current_user, user)
      end
    else
      conn
    end
  end
end
