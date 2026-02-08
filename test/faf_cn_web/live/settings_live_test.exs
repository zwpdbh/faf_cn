defmodule FafCnWeb.SettingsLiveTest do
  use FafCnWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias FafCn.Accounts

  describe "Settings page" do
    setup do
      {:ok, super_admin} =
        Accounts.register_oauth_user(%{
          email: "zwpdbh@outlook.com",
          provider: "github",
          provider_uid: "4442806",
          name: "Super Admin"
        })

      {:ok, admin} =
        Accounts.register_oauth_user(%{
          email: "admin@example.com",
          provider: "github",
          provider_uid: "12345",
          name: "Admin User"
        })

      Accounts.grant_admin_role(admin.id, super_admin.id)

      {:ok, user} =
        Accounts.register_oauth_user(%{
          email: "user@example.com",
          provider: "github",
          provider_uid: "67890",
          name: "Regular User"
        })

      %{super_admin: super_admin, admin: admin, user: user}
    end

    test "super admin can access settings page", %{conn: conn, super_admin: super_admin} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(super_admin)
        |> live(~p"/settings")

      assert html =~ "Settings"
      assert html =~ "Admin Management"
    end

    test "non-super-admin is redirected from settings page", %{conn: conn, user: user} do
      assert {:error, {:live_redirect, %{to: "/", flash: %{"error" => "Unauthorized access"}}}} =
               conn
               |> log_in_user(user)
               |> live(~p"/settings")
    end

    test "settings page lists all users", %{conn: conn, super_admin: super_admin} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(super_admin)
        |> live(~p"/settings")

      assert render(lv) =~ "Super Admin"
      assert render(lv) =~ "Admin User"
      assert render(lv) =~ "Regular User"
    end

    test "super admin can grant admin role", %{conn: conn, super_admin: super_admin, user: user} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(super_admin)
        |> live(~p"/settings")

      # Find the user and click make admin
      lv
      |> element("button", "Make Admin")
      |> render_click()

      assert Accounts.is_admin?(user)
    end

    test "super admin can revoke admin role", %{
      conn: conn,
      super_admin: super_admin,
      admin: admin
    } do
      {:ok, lv, _html} =
        conn
        |> log_in_user(super_admin)
        |> live(~p"/settings")

      # Find the admin and click remove admin
      lv
      |> element("button", "Remove Admin")
      |> render_click()

      refute Accounts.is_admin?(admin)
    end
  end
end
