defmodule FafCn.Accounts do
  @moduledoc """
  The Accounts context.

  Handles user registration, retrieval, and OAuth integration.
  """

  import Ecto.Query, warn: false
  alias FafCn.Repo
  alias FafCn.Accounts.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a single user by their ID.

  Returns `nil` if the User does not exist.

  ## Examples

      iex> get_user(123)
      %User{}

      iex> get_user(456)
      nil

  """
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by provider and provider_uid.

  ## Examples

      iex> get_user_by_provider_and_uid("github", "12345")
      %User{}

      iex> get_user_by_provider_and_uid("github", "unknown")
      nil

  """
  def get_user_by_provider_and_uid(provider, uid)
      when is_binary(provider) and is_binary(uid) do
    Repo.get_by(User, provider: provider, provider_uid: uid)
  end

  def get_user_by_provider_and_uid(_provider, _uid), do: nil

  @doc """
  Registers a user from OAuth data.

  If a user with the same provider and provider_uid exists, updates their info.
  Otherwise creates a new user.

  ## Examples

      iex> register_oauth_user(%{email: "foo@example.com", provider: "github", ...})
      {:ok, %User{}}

      iex> register_oauth_user(%{email: "invalid", ...})
      {:error, %Ecto.Changeset{}}

  """
  def register_oauth_user(attrs) do
    provider = attrs.provider
    uid = attrs.provider_uid

    case get_user_by_provider_and_uid(provider, uid) do
      nil ->
        %User{}
        |> User.changeset(attrs)
        |> Repo.insert()

      user ->
        user
        |> User.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{name: "New Name"})
      {:ok, %User{}}

      iex> update_user(user, %{email: "invalid"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end
end
