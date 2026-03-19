defmodule FafCnWeb.HealthCheck do
  @moduledoc """
  Health check plug for load balancers and monitoring systems.

  Placed at the top of the endpoint to:
  - Avoid SSL redirects (health checks often use HTTP internally)
  - Skip unnecessary processing (logging, sessions, etc.)
  - Respond quickly with minimal overhead

  Returns JSON with server and database health status.

  ## Endpoints

    * `GET /health` - Returns server and database health status
    * `HEAD /health` - Returns only status code (no body)

  ## Response Format

      {
        "status": "healthy",
        "checks": {
          "server": "up",
          "database": "up"
        },
        "timestamp": "2026-03-19T09:30:00Z"
      }

  Returns HTTP 200 if all checks pass, HTTP 503 if any check fails.
  """
  import Plug.Conn

  alias Ecto.Adapters.SQL

  @health_path "/health"
  @health_methods ["GET", "HEAD"]
  @db_check_timeout_ms 5_000

  def init(opts), do: opts

  @doc """
  Handle health check requests before they reach the router.
  """
  def call(%Plug.Conn{request_path: @health_path, method: method} = conn, _opts)
      when method in @health_methods do
    {server_status, db_status} = run_health_checks()

    {overall_status, http_status} =
      case {server_status, db_status} do
        {:up, :up} -> {:healthy, 200}
        {_, _} -> {:unhealthy, 503}
      end

    conn = put_resp_content_type(conn, "application/json")

    case method do
      "HEAD" ->
        conn
        |> send_resp(http_status, "")
        |> halt()

      "GET" ->
        response = build_response(overall_status, server_status, db_status)

        conn
        |> send_resp(http_status, Jason.encode!(response))
        |> halt()
    end
  end

  def call(conn, _opts), do: conn

  # Private functions

  defp run_health_checks do
    db_status = check_database()

    {:up, db_status}
  end

  defp check_database do
    # Use a task with timeout to avoid blocking the health check
    task =
      Task.async(fn ->
        SQL.query(FafCn.Repo, "SELECT 1", [], timeout: @db_check_timeout_ms)
      end)

    case Task.yield(task, @db_check_timeout_ms) || Task.shutdown(task) do
      {:ok, {:ok, _result}} -> :up
      {:ok, {:error, _reason}} -> :down
      # Timeout
      nil -> :down
    end
  rescue
    _ -> :down
  catch
    _ -> :down
  end

  defp build_response(overall_status, server_status, db_status) do
    %{
      status: to_string(overall_status),
      checks: %{
        server: to_string(server_status),
        database: to_string(db_status)
      },
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end
end
