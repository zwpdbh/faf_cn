defmodule FafCnWeb.UserAuth do
  @moduledoc """
  Authentication helpers for LiveView.
  """

  import Phoenix.Component
  import Phoenix.LiveView

  alias FafCn.Accounts

  @doc """
  Assigns the current user to the socket based on the session.

  Use this as an on_mount hook:

      on_mount {FafCnWeb.UserAuth, :mount_current_user}
  """
  def on_mount(:mount_current_user, _params, session, socket) do
    socket = assign_current_user(socket, session)
    {:cont, socket}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = assign_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/")}
    end
  end

  defp assign_current_user(socket, session) do
    case session["user_id"] do
      nil ->
        assign(socket, current_user: nil)

      user_id ->
        case Accounts.get_user(user_id) do
          nil -> assign(socket, current_user: nil)
          user -> assign(socket, current_user: user)
        end
    end
  end

  @doc """
  Checks if a user is authenticated.
  """
  def authenticated?(socket), do: socket.assigns.current_user != nil
end
