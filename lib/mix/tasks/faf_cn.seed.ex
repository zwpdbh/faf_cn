defmodule Mix.Tasks.FafCn.Seed do
  @moduledoc """
  Seeds the database with unit data from priv/repo/units_seed.json.

  This task loads unit data from a local JSON file (committed to git) rather than
  fetching from the FAF API. Use this for:
  
  - New developers setting up the project
  - Production database seeding
  - Resetting local database with known data

  To update the seed file with fresh API data, run:
      mix faf_cn.refresh_units

  ## Examples

      # Seed the database (uses local JSON file)
      mix faf_cn.seed

      # For production (after fly deploy)
      fly ssh console --app faf-cn --command "/app/bin/faf_cn eval 'Mix.Tasks.FafCn.Seed.run([])'"

  """

  use Mix.Task

  require Logger

  alias FafCn.Repo
  alias FafCn.Units
  alias FafCn.Units.Unit

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    seed_file = Path.join([:code.priv_dir(:faf_cn), "repo", "units_seed.json"])

    Logger.info("Loading unit data from #{seed_file}...")

    if File.exists?(seed_file) do
      case File.read!(seed_file) |> Jason.decode() do
        {:ok, %{"units" => units}} ->
          Logger.info("Found #{length(units)} units in seed file")

          # Clear existing units
          Repo.delete_all(Unit)
          Logger.info("Cleared existing units")

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
                Logger.error("Failed to insert unit #{unit_data.unit_id}: #{inspect(changeset.errors)}")
            end
          end)

          count = Repo.aggregate(Unit, :count, :id)
          Logger.info("Successfully inserted #{count} units")

        {:error, reason} ->
          Logger.error("Error parsing seed file: #{inspect(reason)}")
          System.halt(1)
      end
    else
      Logger.error("Seed file not found: #{seed_file}")
      Logger.error("")
      Logger.error("To get unit data, run: mix faf_cn.refresh_units")
      System.halt(1)
    end
  end
end
