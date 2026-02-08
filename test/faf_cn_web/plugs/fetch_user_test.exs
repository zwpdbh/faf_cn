defmodule FafCnWeb.Plugs.FetchUserTest do
  use FafCnWeb.ConnCase, async: true

  alias FafCn.Accounts
  alias FafCnWeb.Plugs.FetchUser

  describe "call/2" do
    test "assigns current_user when user_id is in session", %{conn: conn} do
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
        |> FetchUser.call([])

      assert conn.assigns.current_user.id == user.id
      assert conn.assigns.current_user.email == user.email
    end

    test "does not assign user when session is empty", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> FetchUser.call([])

      refute Map.has_key?(conn.assigns, :current_user)
    end

    test "clears session when user_id refers to deleted user", %{conn: conn} do
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
        |> FetchUser.call([])

      refute Map.has_key?(conn.assigns, :current_user)
      # Session should be cleared
      refute get_session(conn, :user_id)
    end

    test "handles non-integer user_id gracefully", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{user_id: "invalid"})
        |> FetchUser.call([])

      # Should not assign current_user when user_id is not an integer
      refute conn.assigns[:current_user]
    end
  end
end
