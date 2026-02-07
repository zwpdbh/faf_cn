defmodule FafCn.Units.UnitFetcher do
  @moduledoc """
  Module for fetching unit data from the FAF spooky-db API.
  """

  require Logger

  @api_url "https://raw.githubusercontent.com/FAForever/spooky-db/gh-pages/data/97514fd6.index.fat.json"
  @valid_factions ["UEF", "CYBRAN", "AEON", "SERAPHIM"]

  @doc """
  Fetches unit data from the spooky-db API.

  Returns {:ok, units} on success, {:error, reason} on failure.
  """
  def fetch_units do
    Logger.info("Fetching unit data from #{@api_url}")

    case Req.get(@api_url) do
      {:ok, %{status: 200, body: body}} ->
        units = parse_units(body)
        Logger.info("Successfully fetched #{length(units)} units")
        {:ok, units}

      {:ok, %{status: status}} ->
        Logger.error("Failed to fetch units: HTTP #{status}")
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        Logger.error("Failed to fetch units: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Parses the raw JSON data and extracts relevant unit information.
  Only includes units from valid factions (UEF, CYBRAN, AEON, SERAPHIM).
  """
  def parse_units(data) when is_binary(data) do
    case Jason.decode(data) do
      {:ok, %{"units" => units}} ->
        units
        |> Enum.map(&parse_unit/1)
        |> Enum.filter(& &1)

      {:error, reason} ->
        Logger.error("Failed to decode JSON: #{inspect(reason)}")
        []
    end
  end

  def parse_units(%{"units" => units}) do
    units
    |> Enum.map(&parse_unit/1)
    |> Enum.filter(& &1)
  end

  defp parse_unit(raw_unit) do
    unit_id = raw_unit["Id"]
    categories = List.wrap(raw_unit["Categories"])
    faction = extract_faction(categories, unit_id)

    # Only include units from valid factions
    if faction in @valid_factions do
      economy = raw_unit["Economy"] || %{}
      general = raw_unit["General"] || %{}

      %{
        unit_id: unit_id,
        faction: faction,
        name: general["UnitName"],
        description: raw_unit["Description"],
        build_cost_mass: economy["BuildCostMass"] || 0,
        build_cost_energy: economy["BuildCostEnergy"] || 0,
        build_time: economy["BuildTime"] || 0,
        categories: categories |> Enum.reject(&is_nil/1),
        data: raw_unit
      }
    else
      nil
    end
  end

  # Extract faction from categories or unit_id prefix
  defp extract_faction(categories, unit_id) do
    cond do
      "UEF" in categories -> "UEF"
      "CYBRAN" in categories -> "CYBRAN"
      "AEON" in categories -> "AEON"
      "SERAPHIM" in categories -> "SERAPHIM"
      # Fallback to unit_id prefix
      true -> faction_from_unit_id(unit_id)
    end
  end

  defp faction_from_unit_id(<<"UE", _::binary>>), do: "UEF"
  defp faction_from_unit_id(<<"UR", _::binary>>), do: "CYBRAN"
  defp faction_from_unit_id(<<"UA", _::binary>>), do: "AEON"
  defp faction_from_unit_id(<<"XS", _::binary>>), do: "SERAPHIM"
  defp faction_from_unit_id(_), do: nil
end
