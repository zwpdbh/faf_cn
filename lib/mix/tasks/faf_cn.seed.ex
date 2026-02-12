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

    with :ok <- ensure_seed_file_exists(seed_file),
         {:ok, units} <- parse_seed_file(seed_file) do
      seed_units(units)
    else
      {:error, :file_not_found} ->
        Logger.error("Seed file not found: #{seed_file}")
        Logger.error("")
        Logger.error("To get unit data, run: mix faf_cn.refresh_units")
        System.halt(1)

      {:error, reason} ->
        Logger.error("Error parsing seed file: #{inspect(reason)}")
        System.halt(1)
    end
  end

  defp ensure_seed_file_exists(seed_file) do
    if File.exists?(seed_file), do: :ok, else: {:error, :file_not_found}
  end

  defp parse_seed_file(seed_file) do
    case File.read!(seed_file) |> Jason.decode() do
      {:ok, %{"units" => units}} -> {:ok, units}
      {:error, _} = error -> error
    end
  end

  defp seed_units(units) do
    Logger.info("Found #{length(units)} units in seed file")

    Repo.delete_all(Unit)
    Logger.info("Cleared existing units")

    Enum.each(units, &insert_unit/1)

    count = Repo.aggregate(Unit, :count, :id)
    Logger.info("Successfully inserted #{count} units")
  end

  defp insert_unit(unit_data) do
    attrs = %{
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

    case Units.create_unit(attrs) do
      {:ok, _unit} -> :ok
      {:error, changeset} -> log_insert_error(attrs.unit_id, changeset)
    end
  end

  defp log_insert_error(unit_id, changeset) do
    Logger.error("Failed to insert unit #{unit_id}: #{inspect(changeset.errors)}")
  end
end
