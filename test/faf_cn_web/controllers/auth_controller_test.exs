defmodule FafCnWeb.AuthControllerTest do
  use FafCnWeb.ConnCase, async: true

  alias FafCn.Accounts

  describe "GET /auth/github" do
    test "redirects to GitHub OAuth page", %{conn: conn} do
      # Configure test OAuth
      Application.put_env(:faf_cn, :oauth_providers,
        github: [
          client_id: "test_client_id",
          client_secret: "test_client_secret",
          redirect_uri: "http://localhost:4000/auth/github/callback"
        ]
      )

      conn = get(conn, ~p"/auth/github")

      # Should redirect to GitHub
      assert redirected_to(conn, 302)
      assert conn.resp_headers |> List.keyfind("location", 0) |> elem(1) =~ "github.com"
    end
  end

  describe "GET /auth/:provider with unsupported provider" do
    test "redirects to home with error", %{conn: conn} do
      conn = get(conn, ~p"/auth/unsupported")

      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Unsupported OAuth provider"
    end
  end

  describe "GET /auth/github/callback" do
    test "redirects to home when session params missing", %{conn: conn} do
      # Configure test OAuth first
      Application.put_env(:faf_cn, :oauth_providers,
        github: [
          client_id: "test_client_id",
          client_secret: "test_client_secret",
          redirect_uri: "http://localhost:4000/auth/github/callback"
        ]
      )

      # Without proper session setup, the callback will fail
      # This tests that we handle the error gracefully
      conn =
        conn
        # Empty session, no session_params
        |> init_test_session(%{})
        |> get(~p"/auth/github/callback", %{"code" => "invalid", "state" => "invalid"})

      # Should redirect to home with error
      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error)
    end
  end

  describe "GET /logout" do
    test "clears session and redirects to home", %{conn: conn} do
      # First create a session
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
        |> get(~p"/logout")

      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "logged out"
    end
  end
end
