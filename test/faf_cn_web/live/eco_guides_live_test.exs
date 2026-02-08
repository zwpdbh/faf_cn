defmodule FafCnWeb.EcoGuidesLiveTest do
  use FafCnWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias FafCn.Accounts
  alias FafCn.Units

  describe "Eco Comparison unit links" do
    setup do
      # Create base engineer and a comparison unit
      {:ok, base_unit} =
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

      {:ok, tank} =
        Units.create_unit(%{
          unit_id: "UEL0201",
          faction: "UEF",
          name: "MA12 Striker",
          description: "T1 Medium Tank",
          build_cost_mass: 54,
          build_cost_energy: 270,
          build_time: 270,
          categories: ["DIRECTFIRE", "TECH1"]
        })

      {:ok, user} =
        Accounts.register_oauth_user(%{
          email: "test@example.com",
          provider: "github",
          provider_uid: "12345",
          name: "Test User"
        })

      %{base_unit: base_unit, tank: tank, user: user}
    end

    test "logged-in user sees clickable unit links in comparison", %{
      conn: conn,
      user: user,
      tank: tank
    } do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/eco-guides")

      # Select a unit to trigger comparison display
      html = render_click(view, "toggle_unit", %{"unit_id" => tank.unit_id})

      # Should have links in the comparison section (href attribute with /units/)
      assert html =~ "href=\"/units/#{tank.unit_id}\""
    end

    test "non-logged-in user sees plain text unit names in comparison (no links)", %{
      conn: conn,
      tank: tank
    } do
      {:ok, view, _html} =
        live(conn, ~p"/eco-guides")

      # Select a unit to trigger comparison display
      html = render_click(view, "toggle_unit", %{"unit_id" => tank.unit_id})

      # Should NOT have links in the comparison section
      refute html =~ "href=\"/units/#{tank.unit_id}\""
      # But unit name/description should still be visible
      assert html =~ tank.unit_id
    end

    test "base unit (engineer) link behavior for logged-in users", %{
      conn: conn,
      user: user,
      base_unit: base_unit,
      tank: tank
    } do
      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/eco-guides")

      # Select a unit to show comparison with base unit
      html = render_click(view, "toggle_unit", %{"unit_id" => tank.unit_id})

      # Base unit (engineer) should also have a link
      assert html =~ "href=\"/units/#{base_unit.unit_id}\""
    end

    test "base unit (engineer) is plain text for non-logged-in users", %{
      conn: conn,
      base_unit: base_unit,
      tank: tank
    } do
      {:ok, view, _html} =
        live(conn, ~p"/eco-guides")

      # Select a unit to show comparison with base unit
      html = render_click(view, "toggle_unit", %{"unit_id" => tank.unit_id})

      # Base unit should NOT have a link
      refute html =~ "href=\"/units/#{base_unit.unit_id}\""
    end
  end
end
