defmodule FafCn.UnitComments.UnitComment do
  @moduledoc """
  Schema for user comments on units.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias FafCn.Accounts.User
  alias FafCn.Units.Unit

  schema "unit_comments" do
    field :content, :string

    belongs_to :unit, Unit
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(unit_comment, attrs) do
    unit_comment
    |> cast(attrs, [:unit_id, :user_id, :content])
    |> validate_required([:unit_id, :user_id, :content])
    |> validate_length(:content, min: 1, max: 5000)
    |> foreign_key_constraint(:unit_id)
    |> foreign_key_constraint(:user_id)
  end
end
