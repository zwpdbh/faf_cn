# Script for populating the database from local seed file.
#
# For new developers: Run `mix ecto.seed` after `mix ecto.setup`
# To refresh data from FAF API: Run `mix faf_cn.refresh_units`

import Ecto.Query
alias FafCn.Repo
alias FafCn.Units
alias FafCn.Units.Unit

seed_file = Path.join([:code.priv_dir(:faf_cn), "repo", "units_seed.json"])

IO.puts("Loading unit data from #{seed_file}...")

if File.exists?(seed_file) do
  case File.read!(seed_file) |> Jason.decode() do
    {:ok, %{"units" => units}} ->
      IO.puts("Found #{length(units)} units in seed file")

      # Clear existing units
      Repo.delete_all(Unit)
      IO.puts("Cleared existing units")

      # Insert new units
      units
      |> Enum.each(fn unit_data ->
        # Convert string keys to atom keys for the changeset
        unit_data = %{
          unit_id: unit_data["unit_id"],
          faction: unit_data["faction"],
          name: unit_data["name"],
          description: unit_data["description"],
          build_cost_mass: unit_data["build_cost_mass"],
          build_cost_energy: unit_data["build_cost_energy"],
          build_time: unit_data["build_time"],
          categories: unit_data["categories"],
          data: unit_data["data"]
        }

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
      IO.puts("Error parsing seed file: #{inspect(reason)}")
      System.halt(1)
  end
else
  IO.puts("ERROR: Seed file not found: #{seed_file}")
  IO.puts("")
  IO.puts("To get unit data, you have two options:")
  IO.puts("")
  IO.puts("1. Copy units_seed.json from another developer or existing deployment")
  IO.puts("")
  IO.puts("2. Fetch fresh data from FAF API (takes ~10-30 seconds):")
  IO.puts("   mix faf_cn.refresh_units")
  IO.puts("")
  IO.puts("   Then commit the generated units_seed.json file:")
  IO.puts("   git add priv/repo/units_seed.json")
  IO.puts("   git commit -m 'chore: add initial unit seed data'")
  IO.puts("")
  System.halt(1)
end
