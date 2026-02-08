defmodule FafCn.UnitEditLogs.UnitEditLog do
  @moduledoc """
  Schema for tracking unit stat edits (audit log).
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias FafCn.Accounts.User
  alias FafCn.Units.Unit

  schema "unit_edit_logs" do
    field :field, :string
    field :old_value, :string
    field :new_value, :string
    field :reason, :string

    belongs_to :unit, Unit
    belongs_to :editor, User, foreign_key: :edited_by_id

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc false
  def changeset(unit_edit_log, attrs) do
    unit_edit_log
    |> cast(attrs, [:unit_id, :field, :old_value, :new_value, :reason, :edited_by_id])
    |> validate_required([:unit_id, :field, :edited_by_id, :reason])
    |> foreign_key_constraint(:unit_id)
    |> foreign_key_constraint(:edited_by)
  end
end
