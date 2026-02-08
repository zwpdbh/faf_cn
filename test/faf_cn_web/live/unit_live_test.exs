defmodule FafCnWeb.UnitLiveTest do
  use FafCnWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias FafCn.Accounts
  alias FafCn.Units

  describe "Unit detail page" do
    setup do
      {:ok, unit} =
        Units.create_unit(%{
          unit_id: "UEL0105",
          faction: "UEF",
          name: "Engineer",
          description: "T1 Engineer",
          build_cost_mass: 50,
          build_cost_energy: 500,
          build_time: 250,
          categories: ["ENGINEER", "TECH1"]
        })

      {:ok, user} =
        Accounts.register_oauth_user(%{
          email: "test@example.com",
          provider: "github",
          provider_uid: "12345",
          name: "Test User"
        })

      %{unit: unit, user: user}
    end

    test "logged-in user can view unit detail page", %{conn: conn, user: user, unit: unit} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/units/#{unit.unit_id}")

      assert html =~ "UEL0105"
      assert html =~ "Engineer"
      assert html =~ "T1 Engineer"
    end

    test "displays unit stats", %{conn: conn, user: user, unit: unit} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/units/#{unit.unit_id}")

      assert html =~ "50"
      assert html =~ "500"
      assert html =~ "250"
    end

    test "non-logged-in user is redirected", %{conn: conn, unit: unit} do
      assert {:error, {:redirect, %{to: "/"}}} =
               live(conn, ~p"/units/#{unit.unit_id}")
    end

    test "returns error for non-existent unit", %{conn: conn, user: user} do
      assert {:error, {:live_redirect, %{to: "/", flash: %{"error" => _}}}} =
               conn
               |> log_in_user(user)
               |> live(~p"/units/NONEXISTENT")
    end
  end
end
