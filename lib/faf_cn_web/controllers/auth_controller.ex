defmodule FafCnWeb.AuthController do
  @moduledoc """
  Handles OAuth authentication flow.

  Currently supports GitHub, extensible for Google/Microsoft.
  """
  use FafCnWeb, :controller

  alias FafCn.Accounts

  @doc """
  Redirects to the OAuth provider's authorization page.
  """
  def request(conn, %{"provider" => "github"}) do
    case get_github_config() do
      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: "/")

      config ->
        case Assent.Strategy.Github.authorize_url(config) do
          {:ok, %{url: url, session_params: session_params}} ->
            conn
            |> put_session(:oauth_session_params, session_params)
            |> redirect(external: url)

          {:error, error} ->
            conn
            |> put_flash(:error, "Failed to initiate OAuth: #{inspect(error)}")
            |> redirect(to: "/")
        end
    end
  end

  def request(conn, %{"provider" => provider}) do
    conn
    |> put_flash(:error, "Unsupported OAuth provider: #{provider}")
    |> redirect(to: "/")
  end

  @doc """
  Handles the OAuth callback from the provider.
  """
  def callback(conn, %{"provider" => "github"} = params) do
    case get_github_config() do
      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: "/")

      config ->
        session_params = get_session(conn, :oauth_session_params)

        # Check for valid session params
        if is_nil(session_params) do
          conn
          |> put_flash(:error, "Authentication failed: Invalid session")
          |> redirect(to: "/")
        else
          # Add session params to config for callback verification
          config = Keyword.put(config, :session_params, session_params)

          do_github_callback(conn, params, config)
        end
    end
  end

  defp do_github_callback(conn, params, config) do
    require Logger

    with {:ok, %{user: user_info, token: token}} <-
           Assent.Strategy.Github.callback(config, params),
         {:ok, user_info} <- ensure_user_email(user_info, config, token),
         :ok <- validate_github_id(user_info),
         :ok <- validate_github_email(user_info),
         attrs <- build_user_attrs(user_info),
         {:ok, user} <- Accounts.register_oauth_user(attrs) do
      conn
      |> put_session(:user_id, user.id)
      |> configure_session(renew: true)
      |> put_flash(:info, "Welcome, #{user.name || user.email}!")
      |> redirect(to: "/")
    else
      {:error, :missing_github_id} ->
        Logger.error("GitHub OAuth: Missing 'sub' or 'id' in user_info")

        conn
        |> put_flash(:error, "Authentication failed: Missing user ID from GitHub")
        |> redirect(to: "/")

      {:error, :missing_email} ->
        Logger.error("GitHub OAuth: Missing 'email' in user_info")

        conn
        |> put_flash(:error, "Authentication failed: Missing email from GitHub")
        |> redirect(to: "/")

      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Failed to register OAuth user: #{inspect(changeset.errors)}")

        conn
        |> put_flash(:error, "Failed to create account: #{inspect(changeset.errors)}")
        |> redirect(to: "/")

      {:error, error} ->
        Logger.error("GitHub OAuth callback error: #{inspect(error)}")

        conn
        |> put_flash(:error, "Authentication failed: #{inspect(error)}")
        |> redirect(to: "/")
    end
  end

  defp ensure_user_email(user_info, config, token) do
    if user_info["email"] do
      {:ok, user_info}
    else
      case fetch_github_email(config, token) do
        {:ok, email} -> {:ok, Map.put(user_info, "email", email)}
        _ -> {:ok, user_info}
      end
    end
  end

  defp validate_github_id(user_info) do
    if user_info["sub"] || user_info["id"], do: :ok, else: {:error, :missing_github_id}
  end

  defp validate_github_email(user_info) do
    if user_info["email"], do: :ok, else: {:error, :missing_email}
  end

  defp build_user_attrs(user_info) do
    github_id = user_info["sub"] || user_info["id"]
    email = user_info["email"]

    %{
      email: email,
      provider: "github",
      provider_uid: to_string(github_id),
      name: user_info["name"] || user_info["preferred_username"] || user_info["login"] || email,
      avatar_url: user_info["picture"] || user_info["avatar_url"]
    }
  end

  @doc """
  Logs out the current user.
  """
  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "You have been logged out.")
    |> redirect(to: "/")
  end

  # Private functions

  defp get_github_config do
    config =
      Application.fetch_env!(:faf_cn, :oauth_providers)[:github]
      |> Keyword.take([:client_id, :client_secret, :redirect_uri])
      |> Enum.map(fn {k, v} -> {k, to_string(v)} end)

    # Validate config
    client_id = Keyword.get(config, :client_id, "")
    client_secret = Keyword.get(config, :client_secret, "")

    if client_id == "" or client_secret == "" do
      {:error,
       "GitHub OAuth credentials not configured. " <>
         "Please set GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET environment variables."}
    else
      config
    end
  end

  defp fetch_github_email(_config, token) do
    with {:ok, access_token} <- extract_access_token(token),
         {:ok, emails} <- fetch_github_emails_api(access_token),
         email <- find_verified_email(emails) do
      {:ok, email}
    end
  end

  defp extract_access_token(%{access_token: token}) when is_binary(token) do
    {:ok, token}
  end

  defp extract_access_token(%{"access_token" => token}) when is_binary(token) do
    {:ok, token}
  end

  defp extract_access_token(_token) do
    {:error, :no_token}
  end

  defp fetch_github_emails_api(access_token) do
    case Req.get("https://api.github.com/user/emails",
           headers: [
             {"authorization", "token #{access_token}"},
             {"accept", "application/vnd.github.v3+json"}
           ]
         ) do
      {:ok, %{status: 200, body: emails}} when is_list(emails) ->
        {:ok, emails}

      error ->
        require Logger
        Logger.warning("Failed to fetch GitHub emails: #{inspect(error)}")
        {:error, :no_email}
    end
  end

  defp find_verified_email(emails) do
    emails
    |> Enum.find(fn e -> e["primary"] && e["verified"] end)
    |> Kernel.||(Enum.find(emails, & &1["verified"]))
    |> case do
      nil -> {:error, :no_email}
      email -> {:ok, email["email"]}
    end
  end
end
