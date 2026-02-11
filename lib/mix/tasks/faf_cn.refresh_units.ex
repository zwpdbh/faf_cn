defmodule Mix.Tasks.FafCn.RefreshUnits do
  @moduledoc """
  Fetches unit data from FAF spooky-db API and saves it to priv/repo/units_seed.json.

  This should be run occasionally (e.g., every few months) when unit data needs updating.
  New developers should use `mix ecto.seed` instead, which loads from the local JSON file.

  ## Examples

      # Fetch from API and update local seed file
      mix faf_cn.refresh_units

  """

  use Mix.Task

  require Logger

  alias FafCn.Units.UnitFetcher

  @seed_file_path "priv/repo/units_seed.json"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    Logger.info("Fetching unit data from FAF spooky-db API...")

    case UnitFetcher.fetch_units() do
      {:ok, units} ->
        Logger.info("Fetched #{length(units)} units from API")

        # Save to JSON file
        seed_data = %{
          "fetched_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "source" => "FAF spooky-db",
          "units" => units
        }

        json = Jason.encode!(seed_data, pretty: true)
        File.write!(@seed_file_path, json)

        Logger.info("Saved #{length(units)} units to #{@seed_file_path}")
        Logger.info("Next steps:")
        Logger.info("  1. Review the changes: git diff #{@seed_file_path}")
        Logger.info("  2. Commit the updated seed file: git add #{@seed_file_path}")
        Logger.info("  3. Run seeds to update database: mix ecto.seed")

      {:error, reason} ->
        Logger.error("Failed to fetch units: #{inspect(reason)}")
        System.halt(1)
    end
  end
end
