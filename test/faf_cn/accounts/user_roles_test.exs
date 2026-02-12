defmodule FafCn.Accounts.UserRolesTest do
  use FafCn.DataCase, async: false

  alias FafCn.Accounts
  alias FafCn.Accounts.UserRole

  setup do
    # Set up super admin env vars for tests
    System.put_env("SUPER_ADMIN_EMAIL", "superadmin@example.com")
    System.put_env("SUPER_ADMIN_GITHUB_ID", "99999")

    on_exit(fn ->
      System.delete_env("SUPER_ADMIN_EMAIL")
      System.delete_env("SUPER_ADMIN_GITHUB_ID")
    end)

    :ok
  end

  describe "grant_admin_role/2" do
    setup do
      {:ok, super_admin} =
        Accounts.register_oauth_user(%{
          email: "superadmin@example.com",
          provider: "github",
          provider_uid: "99999",
          name: "Super Admin"
        })

      {:ok, user} =
        Accounts.register_oauth_user(%{
          email: "user@example.com",
          provider: "github",
          provider_uid: "12345",
          name: "Regular User"
        })

      %{super_admin: super_admin, user: user}
    end

    test "grants admin role successfully by super admin", %{super_admin: super_admin, user: user} do
      assert {:ok, %UserRole{role: "admin"}} =
               Accounts.grant_admin_role(user.id, super_admin.id)

      assert Accounts.admin?(user)
    end

    test "returns error when non-super-admin tries to grant", %{user: user} do
      {:ok, other_user} =
        Accounts.register_oauth_user(%{
          email: "other@example.com",
          provider: "github",
          provider_uid: "88888",
          name: "Other User"
        })

      assert {:error, "Unauthorized"} = Accounts.grant_admin_role(user.id, other_user.id)
    end

    test "returns error when user already has admin role", %{super_admin: super_admin, user: user} do
      {:ok, _} = Accounts.grant_admin_role(user.id, super_admin.id)
      assert {:error, _} = Accounts.grant_admin_role(user.id, super_admin.id)
    end
  end

  describe "revoke_admin_role/2" do
    setup do
      {:ok, super_admin} =
        Accounts.register_oauth_user(%{
          email: "superadmin@example.com",
          provider: "github",
          provider_uid: "99999",
          name: "Super Admin"
        })

      {:ok, user} =
        Accounts.register_oauth_user(%{
          email: "user@example.com",
          provider: "github",
          provider_uid: "12345",
          name: "Regular User"
        })

      Accounts.grant_admin_role(user.id, super_admin.id)
      %{super_admin: super_admin, user: user}
    end

    test "revokes admin role successfully by super admin", %{super_admin: super_admin, user: user} do
      assert {:ok, _} = Accounts.revoke_admin_role(user.id, super_admin.id)
      refute Accounts.admin?(user)
    end

    test "returns error when non-super-admin tries to revoke", %{user: user} do
      {:ok, other_user} =
        Accounts.register_oauth_user(%{
          email: "other@example.com",
          provider: "github",
          provider_uid: "88888",
          name: "Other User"
        })

      assert {:error, "Unauthorized"} = Accounts.revoke_admin_role(user.id, other_user.id)
    end

    test "returns error when user doesn't have admin role", %{super_admin: super_admin} do
      {:ok, non_admin} =
        Accounts.register_oauth_user(%{
          email: "nonadmin@example.com",
          provider: "github",
          provider_uid: "88888",
          name: "Non Admin"
        })

      assert {:error, _} = Accounts.revoke_admin_role(non_admin.id, super_admin.id)
    end
  end

  describe "admin?/1" do
    test "returns true for admin user" do
      {:ok, super_admin} =
        Accounts.register_oauth_user(%{
          email: "superadmin@example.com",
          provider: "github",
          provider_uid: "99999",
          name: "Super Admin"
        })

      {:ok, user} =
        Accounts.register_oauth_user(%{
          email: "user@example.com",
          provider: "github",
          provider_uid: "12345",
          name: "Regular User"
        })

      Accounts.grant_admin_role(user.id, super_admin.id)
      assert Accounts.admin?(user)
    end

    test "returns false for non-admin user" do
      {:ok, user} =
        Accounts.register_oauth_user(%{
          email: "user@example.com",
          provider: "github",
          provider_uid: "12345",
          name: "Regular User"
        })

      refute Accounts.admin?(user)
    end

    test "returns false for nil user" do
      refute Accounts.admin?(nil)
    end
  end

  describe "super_admin?/1" do
    test "returns true for configured super admin by email" do
      System.put_env("SUPER_ADMIN_EMAIL", "admin@example.com")
      on_exit(fn -> System.delete_env("SUPER_ADMIN_EMAIL") end)

      {:ok, user} =
        Accounts.register_oauth_user(%{
          email: "admin@example.com",
          provider: "github",
          provider_uid: "12345",
          name: "Super Admin"
        })

      assert Accounts.super_admin?(user)
    end

    test "returns true for configured super admin by provider_uid" do
      System.put_env("SUPER_ADMIN_GITHUB_ID", "99999")
      on_exit(fn -> System.delete_env("SUPER_ADMIN_GITHUB_ID") end)

      {:ok, user} =
        Accounts.register_oauth_user(%{
          email: "other@example.com",
          provider: "github",
          provider_uid: "99999",
          name: "Super Admin"
        })

      assert Accounts.super_admin?(user)
    end

    test "returns false for other users" do
      System.put_env("SUPER_ADMIN_EMAIL", "admin@example.com")
      System.put_env("SUPER_ADMIN_GITHUB_ID", "99999")

      on_exit(fn ->
        System.delete_env("SUPER_ADMIN_EMAIL")
        System.delete_env("SUPER_ADMIN_GITHUB_ID")
      end)

      {:ok, user} =
        Accounts.register_oauth_user(%{
          email: "other@example.com",
          provider: "github",
          provider_uid: "12345",
          name: "Other User"
        })

      refute Accounts.super_admin?(user)
    end
  end

  describe "list_admins/0" do
    test "returns list of admin users" do
      {:ok, super_admin} =
        Accounts.register_oauth_user(%{
          email: "superadmin@example.com",
          provider: "github",
          provider_uid: "99999",
          name: "Super Admin"
        })

      {:ok, user} =
        Accounts.register_oauth_user(%{
          email: "user@example.com",
          provider: "github",
          provider_uid: "12345",
          name: "Regular User"
        })

      Accounts.grant_admin_role(user.id, super_admin.id)

      admins = Accounts.list_admins()
      assert length(admins) == 1
      assert hd(admins).id == user.id
    end

    test "returns empty list when no admins" do
      assert Accounts.list_admins() == []
    end
  end
end
