defmodule FafCnWeb.UserAuthTest do
  use FafCnWeb.ConnCase, async: true

  alias FafCn.Accounts
  alias FafCnWeb.UserAuth

  describe "UserAuth.on_mount :mount_current_user" do
    test "assigns current_user from session", %{conn: conn} do
      {:ok, user} =
        Accounts.register_oauth_user(%{
          email: "test@example.com",
          provider: "github",
          provider_uid: "12345",
          name: "Test User"
        })

      conn =
        conn
        |> init_test_session(%{user_id: user.id})
        |> get(~p"/")

      # The user should be assigned
      assert conn.assigns.current_user.id == user.id
    end

    test "assigns nil when no user in session", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> get(~p"/")

      # Should not have current_user
      refute conn.assigns[:current_user]
    end

    test "handles deleted user gracefully", %{conn: conn} do
      {:ok, user} =
        Accounts.register_oauth_user(%{
          email: "test@example.com",
          provider: "github",
          provider_uid: "12345",
          name: "Test User"
        })

      # Delete the user
      Accounts.delete_user(user)

      conn =
        conn
        |> init_test_session(%{user_id: user.id})
        |> get(~p"/")

      # Should not have current_user (user deleted)
      refute conn.assigns[:current_user]
    end
  end

  describe "UserAuth.authenticated?/1" do
    test "returns true when user is assigned" do
      socket = %Phoenix.LiveView.Socket{assigns: %{current_user: %{id: 1}}}
      assert UserAuth.authenticated?(socket)
    end

    test "returns false when user is nil" do
      socket = %Phoenix.LiveView.Socket{assigns: %{current_user: nil}}
      refute UserAuth.authenticated?(socket)
    end
  end
end
