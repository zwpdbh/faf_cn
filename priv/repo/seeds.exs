# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     FafCn.Repo.insert!(%FafCn.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import Ecto.Query
alias FafCn.Repo
alias FafCn.Units
alias FafCn.Units.Unit
alias FafCn.Units.UnitFetcher

IO.puts("Fetching unit data from FAF spooky-db...")

case UnitFetcher.fetch_units() do
  {:ok, units} ->
    IO.puts("Found #{length(units)} units from valid factions")

    # Clear existing units
    Repo.delete_all(Unit)
    IO.puts("Cleared existing units")

    # Insert new units
    units
    |> Enum.each(fn unit_data ->
      case Units.create_unit(unit_data) do
        {:ok, _unit} ->
          :ok

        {:error, changeset} ->
          IO.puts("Failed to insert unit #{unit_data.unit_id}: #{inspect(changeset.errors)}")
      end
    end)

    count = Repo.aggregate(Unit, :count, :id)
    IO.puts("Successfully inserted #{count} units")

  {:error, reason} ->
    IO.puts("Error fetching units: #{inspect(reason)}")
    System.halt(1)
end
