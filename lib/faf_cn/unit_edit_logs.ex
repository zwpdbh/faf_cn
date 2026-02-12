defmodule FafCn.UnitEditLogs do
  @moduledoc """
  The UnitEditLogs context for tracking unit statistic edits.
  """

  import Ecto.Query, warn: false

  alias FafCn.Repo
  alias FafCn.UnitEditLogs.UnitEditLog
  alias FafCn.Units.Unit
  alias FafCn.Accounts

  @doc """
  Logs a unit edit to the audit trail.

  ## Examples

      iex> log_unit_edit(unit_id, "build_cost_mass", "50", "60", "Balance update", user_id)
      {:ok, %UnitEditLog{}}

      iex> log_unit_edit(unit_id, "build_cost_mass", "50", "60", "", user_id)
      {:error, %Ecto.Changeset{}}

  """
  def log_unit_edit(unit_id, field, old_value, new_value, reason, edited_by_id) do
    %UnitEditLog{}
    |> UnitEditLog.changeset(%{
      unit_id: unit_id,
      field: field,
      old_value: to_string(old_value),
      new_value: to_string(new_value),
      reason: reason,
      edited_by_id: edited_by_id
    })
    |> Repo.insert()
  end

  @doc """
  Returns the list of edit logs for a unit, ordered by newest first.

  ## Examples

      iex> list_unit_edit_logs(unit_id)
      [%UnitEditLog{}, ...]

  """
  def list_unit_edit_logs(unit_id) do
    UnitEditLog
    |> where(unit_id: ^unit_id)
    |> order_by([l], desc: l.inserted_at, desc: l.id)
    |> preload(:editor)
    |> Repo.all()
  end

  @doc """
  Updates a unit statistic and logs the change.

  ## Examples

      iex> update_unit_stat(unit, "build_cost_mass", "60", "Balance update", user_id)
      {:ok, %Unit{}}

      iex> update_unit_stat(unit, "build_cost_mass", "60", "", user_id)
      {:error, %Ecto.Changeset{}}

  """
  def update_unit_stat(unit, field, new_value, reason, user_id) do
    editor = Accounts.get_user!(user_id)

    if Accounts.admin?(editor) do
      do_update_stat(unit, field, new_value, reason, user_id)
    else
      {:error, "Unauthorized"}
    end
  end

  defp do_update_stat(unit, field, new_value, reason, user_id) do
    old_value = Map.get(unit, String.to_atom(field))
    new_value_int = maybe_to_integer(new_value)

    # Only log and update if the value actually changed
    if to_string(old_value) == to_string(new_value_int) do
      # No change needed, return the unit as-is
      {:ok, unit}
    else
      perform_stat_update(unit, field, old_value, new_value_int, reason, user_id)
    end
  end

  defp perform_stat_update(unit, field, old_value, new_value_int, reason, user_id) do
    Repo.transaction(fn ->
      do_stat_update_transaction(unit, field, old_value, new_value_int, reason, user_id)
    end)
    |> handle_stat_update_result()
  end

  defp do_stat_update_transaction(unit, field, old_value, new_value_int, reason, user_id) do
    case log_unit_edit(unit.id, field, old_value, new_value_int, reason, user_id) do
      {:ok, _log} ->
        unit
        |> Unit.changeset(%{String.to_atom(field) => new_value_int})
        |> Repo.update!()

      {:error, changeset} ->
        Repo.rollback(changeset)
    end
  end

  defp handle_stat_update_result({:ok, unit}), do: {:ok, unit}
  defp handle_stat_update_result({:error, changeset}), do: {:error, changeset}

  defp maybe_to_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> int
      _ -> value
    end
  end

  defp maybe_to_integer(value), do: value
end
