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
    
    # Start the repo
    {:ok, _} = Application.ensure_all_started(:ecto_sql)
    {:ok, _} = FafCn.Repo.start_link()

    seed_file = Path.join([:code.priv_dir(@app), "repo", "units_seed.json"])

    IO.puts("Loading unit data from #{seed_file}...")

    if File.exists?(seed_file) do
      case File.read!(seed_file) |> Jason.decode() do
        {:ok, %{"units" => units}} ->
          IO.puts("Found #{length(units)} units in seed file")

          alias FafCn.Repo
          alias FafCn.Units
          alias FafCn.Units.Unit

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
      IO.puts("To get unit data, you need to:")
      IO.puts("1. Run locally: mix faf_cn.refresh_units")
      IO.puts("2. Commit the generated units_seed.json file")
      IO.puts("3. Redeploy the application")
      System.halt(1)
    end
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
