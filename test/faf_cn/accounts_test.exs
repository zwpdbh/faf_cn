defmodule FafCn.AccountsTest do
  use FafCn.DataCase, async: true

  alias FafCn.Accounts
  alias FafCn.Accounts.User

  describe "users" do
    @valid_attrs %{
      email: "user@example.com",
      provider: "github",
      provider_uid: "12345",
      name: "Test User",
      avatar_url: "https://example.com/avatar.png"
    }

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.register_oauth_user()

      user
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "get_user/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user(user.id) == user
    end

    test "get_user/1 returns nil for non-existent id" do
      assert Accounts.get_user(999_999) == nil
    end

    test "get_user_by_email/1 returns the user with given email" do
      user = user_fixture()
      assert Accounts.get_user_by_email(user.email) == user
    end

    test "get_user_by_email/1 returns nil for non-existent email" do
      assert Accounts.get_user_by_email("nonexistent@example.com") == nil
    end

    test "get_user_by_provider_and_uid/2 returns the user" do
      user = user_fixture()
      assert Accounts.get_user_by_provider_and_uid(user.provider, user.provider_uid) == user
    end

    test "get_user_by_provider_and_uid/2 returns nil for non-existent user" do
      assert Accounts.get_user_by_provider_and_uid("github", "99999") == nil
    end
  end

  describe "register_oauth_user/1" do
    @valid_attrs %{
      email: "user@example.com",
      provider: "github",
      provider_uid: "12345",
      name: "Test User",
      avatar_url: "https://example.com/avatar.png"
    }

    test "creates a new user with valid data" do
      assert {:ok, %User{} = user} = Accounts.register_oauth_user(@valid_attrs)
      assert user.email == "user@example.com"
      assert user.provider == "github"
      assert user.provider_uid == "12345"
      assert user.name == "Test User"
      assert user.avatar_url == "https://example.com/avatar.png"
    end

    test "updates existing user with same provider and uid" do
      # Create initial user
      {:ok, original} = Accounts.register_oauth_user(@valid_attrs)

      # Update with new data
      updated_attrs = %{
        email: "newemail@example.com",
        provider: "github",
        provider_uid: "12345",
        name: "Updated Name",
        avatar_url: "https://example.com/new.png"
      }

      assert {:ok, %User{} = updated} = Accounts.register_oauth_user(updated_attrs)
      assert updated.id == original.id
      assert updated.email == "newemail@example.com"
      assert updated.name == "Updated Name"
    end

    test "creates different users for different provider_uids" do
      {:ok, user1} = Accounts.register_oauth_user(@valid_attrs)

      {:ok, user2} =
        Accounts.register_oauth_user(%{
          email: "user2@example.com",
          provider: "github",
          provider_uid: "99999",
          name: "User Two"
        })

      assert user1.id != user2.id
    end

    test "returns error changeset with invalid data" do
      assert {:error, changeset} =
               Accounts.register_oauth_user(%{email: nil, provider: nil, provider_uid: nil})

      assert "can't be blank" in errors_on(changeset).email
      assert "can't be blank" in errors_on(changeset).provider
      assert "can't be blank" in errors_on(changeset).provider_uid
    end

    test "enforces unique email constraint" do
      {:ok, _user} = Accounts.register_oauth_user(@valid_attrs)

      assert {:error, changeset} =
               Accounts.register_oauth_user(%{
                 email: "user@example.com",
                 provider: "github",
                 provider_uid: "different_uid",
                 name: "Another User"
               })

      assert "has already been taken" in errors_on(changeset).email
    end

    test "updates existing user with same provider + provider_uid (upsert behavior)" do
      {:ok, original} = Accounts.register_oauth_user(@valid_attrs)

      # Same provider/uid should update the existing user
      assert {:ok, updated} =
               Accounts.register_oauth_user(%{
                 email: "different@example.com",
                 provider: "github",
                 provider_uid: "12345",
                 name: "Updated Name"
               })

      assert updated.id == original.id
      assert updated.name == "Updated Name"
      assert updated.email == "different@example.com"
    end

    test "validates email format" do
      assert {:error, changeset} =
               Accounts.register_oauth_user(%{
                 email: "invalid-email",
                 provider: "github",
                 provider_uid: "12345"
               })

      assert "has invalid format" in errors_on(changeset).email
    end
  end

  describe "update_user/2" do
    test "updates the user with valid data" do
      user = user_fixture()
      assert {:ok, %User{} = updated} = Accounts.update_user(user, %{name: "New Name"})
      assert updated.name == "New Name"
    end

    test "returns error changeset with invalid data" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, %{email: nil})
    end
  end

  describe "delete_user/1" do
    test "deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert Accounts.get_user(user.id) == nil
    end
  end

  describe "change_user/2" do
    test "returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end
end
