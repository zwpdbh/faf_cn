defmodule FafCnWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use FafCnWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint FafCnWeb.Endpoint

      use FafCnWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import FafCnWeb.ConnCase

      # Authentication test helpers
      alias FafCn.Accounts

      def user_fixture(attrs \\ %{}) do
        {:ok, user} =
          attrs
          |> Enum.into(%{
            email: "user#{System.unique_integer()}@example.com",
            provider: "github",
            provider_uid: "#{System.unique_integer()}",
            name: "Test User"
          })
          |> Accounts.register_oauth_user()

        user
      end

      def log_in_user(conn, user) do
        init_test_session(conn, %{user_id: user.id})
      end
    end
  end

  setup tags do
    FafCn.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
