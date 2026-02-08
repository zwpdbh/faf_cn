defmodule FafCnWeb.SettingsLive do
  @moduledoc """
  Settings page for admin management.
  Only accessible by super admin (zwpdbh).
  """
  use FafCnWeb, :live_view

  alias FafCn.Accounts

  on_mount {FafCnWeb.UserAuth, :mount_current_user}

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    if current_user && Accounts.is_super_admin?(current_user) do
      users = Accounts.list_users()
      admins = Accounts.list_admins()

      socket =
        socket
        |> assign(:page_title, "Settings")
        |> assign(:users, users)
        |> assign(:admins, admins)

      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "Unauthorized access")
       |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("grant_admin", %{"user-id" => user_id}, socket) do
    current_user = socket.assigns.current_user

    case Accounts.grant_admin_role(String.to_integer(user_id), current_user.id) do
      {:ok, _} ->
        admins = Accounts.list_admins()
        {:noreply, assign(socket, :admins, admins)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to grant admin role")}
    end
  end

  @impl true
  def handle_event("revoke_admin", %{"user-id" => user_id}, socket) do
    current_user = socket.assigns.current_user

    case Accounts.revoke_admin_role(String.to_integer(user_id), current_user.id) do
      {:ok, _} ->
        admins = Accounts.list_admins()
        {:noreply, assign(socket, :admins, admins)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to revoke admin role")}
    end
  end
end
