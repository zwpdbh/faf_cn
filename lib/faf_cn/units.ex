defmodule FafCn.Units do
  @moduledoc """
  The Units context.
  """
  import Ecto.Query, warn: false
  alias FafCn.Repo
  alias FafCn.Units.Unit

  @doc """
  Returns the list of units.

  ## Examples

      iex> list_units()
      [%Unit{}, ...]

  """
  def list_units do
    Repo.all(Unit)
  end

  @doc """
  Returns the list of units for eco guides display.
  Selects only essential fields to reduce memory usage (~16x reduction).
  Excludes the large 'data' JSON field which is only needed for unit detail pages.

  ## Examples

      iex> list_units_for_eco_guides()
      [%Unit{}, ...]

  """
  def list_units_for_eco_guides do
    Unit
    |> select([u], map(u, [:id, :unit_id, :faction, :name, :description,
                           :build_cost_mass, :build_cost_energy, :build_time, :categories]))
    |> Repo.all()
  end

  @doc """
  Returns the list of units for specific factions.

  ## Examples

      iex> list_units_by_factions(["UEF", "CYBRAN"])
      [%Unit{}, ...]

  """
  def list_units_by_factions(factions) do
    Unit
    |> where([u], u.faction in ^factions)
    |> Repo.all()
  end

  @doc """
  Gets a single unit.

  Raises `Ecto.NoResultsError` if the Unit does not exist.

  ## Examples

      iex> get_unit!(123)
      %Unit{}

      iex> get_unit!(456)
      ** (Ecto.NoResultsError)

  """
  def get_unit!(id), do: Repo.get!(Unit, id)

  @doc """
  Gets a single unit by unit_id.

  ## Examples

      iex> get_unit_by_unit_id("UEB0101")
      %Unit{}

      iex> get_unit_by_unit_id("invalid")
      nil

  """
  def get_unit_by_unit_id(unit_id) do
    Repo.get_by(Unit, unit_id: unit_id)
  end

  @doc """
  Creates a unit.

  ## Examples

      iex> create_unit(%{field: value})
      {:ok, %Unit{}}

      iex> create_unit(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_unit(attrs \\ %{}) do
    %Unit{}
    |> Unit.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates or updates a unit based on unit_id.

  ## Examples

      iex> upsert_unit(%{unit_id: "UEB0101", ...})
      {:ok, %Unit{}}

  """
  def upsert_unit(attrs) do
    case get_unit_by_unit_id(attrs.unit_id) do
      nil ->
        create_unit(attrs)

      unit ->
        unit
        |> Unit.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Updates a unit.

  ## Examples

      iex> update_unit(unit, %{field: new_value})
      {:ok, %Unit{}}

      iex> update_unit(unit, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_unit(%Unit{} = unit, attrs) do
    unit
    |> Unit.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a unit.

  ## Examples

      iex> delete_unit(unit)
      {:ok, %Unit{}}

      iex> delete_unit(unit)
      {:error, %Ecto.Changeset{}}

  """
  def delete_unit(%Unit{} = unit) do
    Repo.delete(unit)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking unit changes.

  ## Examples

      iex> change_unit(unit)
      %Ecto.Changeset{data: %Unit{}}

  """
  def change_unit(%Unit{} = unit, attrs \\ %{}) do
    Unit.changeset(unit, attrs)
  end
end
