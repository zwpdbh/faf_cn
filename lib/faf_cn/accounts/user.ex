defmodule FafCn.Accounts.User do
  @moduledoc """
  Schema for user accounts via OAuth.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :provider, :string
    field :provider_uid, :string
    field :name, :string
    field :avatar_url, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :provider, :provider_uid, :name, :avatar_url])
    |> validate_required([:email, :provider, :provider_uid])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> unique_constraint(:email)
    |> unique_constraint([:provider, :provider_uid])
  end
end
