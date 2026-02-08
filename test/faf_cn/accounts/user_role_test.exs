defmodule FafCn.Accounts.UserRoleTest do
  use FafCn.DataCase, async: true

  alias FafCn.Accounts
  alias FafCn.Accounts.UserRole

  describe "user_roles schema" do
    test "changeset with valid attributes" do
      {:ok, user} =
        Accounts.register_oauth_user(%{
          email: "test@example.com",
          provider: "github",
          provider_uid: "12345",
          name: "Test User"
        })

      {:ok, admin_user} =
        Accounts.register_oauth_user(%{
          email: "admin@example.com",
          provider: "github",
          provider_uid: "67890",
          name: "Admin User"
        })

      attrs = %{
        user_id: user.id,
        role: "admin",
        granted_by: admin_user.id,
        granted_at: DateTime.utc_now()
      }

      assert %Ecto.Changeset{valid?: true} = UserRole.changeset(%UserRole{}, attrs)
    end

    test "changeset requires user_id" do
      attrs = %{
        role: "admin",
        granted_at: DateTime.utc_now()
      }

      changeset = UserRole.changeset(%UserRole{}, attrs)
      assert "can't be blank" in errors_on(changeset).user_id
    end

    test "changeset requires role" do
      {:ok, user} =
        Accounts.register_oauth_user(%{
          email: "test@example.com",
          provider: "github",
          provider_uid: "12345",
          name: "Test User"
        })

      attrs = %{
        user_id: user.id,
        granted_at: DateTime.utc_now()
      }

      changeset = UserRole.changeset(%UserRole{}, attrs)
      assert "can't be blank" in errors_on(changeset).role
    end

    test "changeset requires granted_at" do
      {:ok, user} =
        Accounts.register_oauth_user(%{
          email: "test@example.com",
          provider: "github",
          provider_uid: "12345",
          name: "Test User"
        })

      attrs = %{
        user_id: user.id,
        role: "admin"
      }

      changeset = UserRole.changeset(%UserRole{}, attrs)
      assert "can't be blank" in errors_on(changeset).granted_at
    end
  end
end
