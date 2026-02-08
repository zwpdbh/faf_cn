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
    config = get_github_config()

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

  def request(conn, %{"provider" => provider}) do
    conn
    |> put_flash(:error, "Unsupported OAuth provider: #{provider}")
    |> redirect(to: "/")
  end

  @doc """
  Handles the OAuth callback from the provider.
  """
  def callback(conn, %{"provider" => "github"} = params) do
    config = get_github_config()
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

  defp do_github_callback(conn, params, config) do
    case Assent.Strategy.Github.callback(config, params) do
      {:ok, %{user: user_info, token: token}} ->
        # Fetch additional user info (email) if not provided
        user_info =
          case user_info["email"] do
            nil ->
              case fetch_github_email(config, token) do
                {:ok, email} -> Map.put(user_info, "email", email)
                _ -> user_info
              end

            _ ->
              user_info
          end

        attrs = %{
          email: user_info["email"],
          provider: "github",
          provider_uid: to_string(user_info["id"]),
          name: user_info["name"] || user_info["login"],
          avatar_url: user_info["avatar_url"]
        }

        case Accounts.register_oauth_user(attrs) do
          {:ok, user} ->
            conn
            |> put_session(:user_id, user.id)
            |> configure_session(renew: true)
            |> put_flash(:info, "Welcome, #{user.name || user.email}!")
            |> redirect(to: "/")

          {:error, changeset} ->
            conn
            |> put_flash(:error, "Failed to create account: #{inspect(changeset.errors)}")
            |> redirect(to: "/")
        end

      {:error, error} ->
        conn
        |> put_flash(:error, "Authentication failed: #{inspect(error)}")
        |> redirect(to: "/")
    end
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
    Application.fetch_env!(:faf_cn, :oauth_providers)[:github]
    |> Keyword.take([:client_id, :client_secret, :redirect_uri])
    |> Enum.map(fn {k, v} -> {k, to_string(v)} end)
  end

  defp fetch_github_email(_config, token) do
    # GitHub doesn't always return email in user info, fetch from emails endpoint
    access_token = token.access_token

    case Req.get("https://api.github.com/user/emails",
           headers: [
             {"authorization", "token #{access_token}"},
             {"accept", "application/vnd.github.v3+json"}
           ]
         ) do
      {:ok, %{status: 200, body: emails}} when is_list(emails) ->
        # Find primary verified email
        email =
          emails
          |> Enum.find(fn e -> e["primary"] && e["verified"] end)
          |> Kernel.||(Enum.find(emails, & &1["verified"]))

        {:ok, email && email["email"]}

      _ ->
        {:error, :no_email}
    end
  end
end
