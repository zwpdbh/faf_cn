defmodule FafCn.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :faf_cn

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  @doc """
  Seeds the database with unit data from priv/repo/units_seed.json.
  Run this after migrations to populate the units table.
  """
  def seed do
    load_app()
    start_repo()

    seed_file = Path.join([:code.priv_dir(@app), "repo", "units_seed.json"])
    IO.puts("Loading unit data from #{seed_file}...")

    with :ok <- ensure_seed_file_exists(seed_file),
         {:ok, units} <- parse_seed_file(seed_file) do
      do_seed_units(units)
    else
      {:error, :file_not_found} ->
        IO.puts("ERROR: Seed file not found: #{seed_file}")
        IO.puts("")
        IO.puts("To get unit data, you need to:")
        IO.puts("1. Run locally: mix faf_cn.refresh_units")
        IO.puts("2. Commit the generated units_seed.json file")
        IO.puts("3. Redeploy the application")
        System.halt(1)

      {:error, reason} ->
        IO.puts("Error parsing seed file: #{inspect(reason)}")
        System.halt(1)
    end
  end

  defp start_repo do
    {:ok, _} = Application.ensure_all_started(:ecto_sql)
    {:ok, _} = FafCn.Repo.start_link()
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

  defp do_seed_units(units) do
    alias FafCn.Repo
    alias FafCn.Units.Unit

    IO.puts("Found #{length(units)} units in seed file")

    Repo.delete_all(Unit)
    IO.puts("Cleared existing units")

    Enum.each(units, &insert_unit/1)

    count = Repo.aggregate(Unit, :count, :id)
    IO.puts("Successfully inserted #{count} units")
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

    case FafCn.Units.create_unit(attrs) do
      {:ok, _unit} -> :ok
      {:error, changeset} -> log_insert_error(attrs.unit_id, changeset)
    end
  end

  defp log_insert_error(unit_id, changeset) do
    IO.puts("Failed to insert unit #{unit_id}: #{inspect(changeset.errors)}")
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    # Many platforms require SSL when connecting to the database
    Application.ensure_all_started(:ssl)
    Application.ensure_loaded(@app)
  end
end
