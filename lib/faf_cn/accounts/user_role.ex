defmodule FafCn.Accounts.UserRole do
  @moduledoc """
  Schema for user roles (e.g., admin).
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_roles" do
    field :role, :string
    field :granted_at, :utc_datetime

    belongs_to :user, FafCn.Accounts.User
    belongs_to :grantor, FafCn.Accounts.User, foreign_key: :granted_by

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_role, attrs) do
    user_role
    |> cast(attrs, [:user_id, :role, :granted_by, :granted_at])
    |> validate_required([:user_id, :role, :granted_at])
    |> unique_constraint([:user_id, :role])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:granted_by)
  end
end
