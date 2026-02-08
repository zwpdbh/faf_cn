defmodule FafCnWeb.UnitLiveEditTest do
  use FafCnWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias FafCn.Accounts
  alias FafCn.Units

  describe "Admin edit form" do
    setup %{conn: conn} do
      {:ok, admin} =
        Accounts.register_oauth_user(%{
          email: "admin@example.com",
          provider: "github",
          provider_uid: "12345",
          name: "Admin User"
        })

      {:ok, super_admin} =
        Accounts.register_oauth_user(%{
          email: "zwpdbh@outlook.com",
          provider: "github",
          provider_uid: "4442806",
          name: "Super Admin"
        })

      Accounts.grant_admin_role(admin.id, super_admin.id)

      {:ok, non_admin} =
        Accounts.register_oauth_user(%{
          email: "user@example.com",
          provider: "github",
          provider_uid: "99999",
          name: "Regular User"
        })

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

      %{conn: conn, admin: admin, non_admin: non_admin, unit: unit}
    end

    test "admin sees edit form for unit stats", %{conn: conn, admin: admin, unit: unit} do
      {:ok, view, _html} = conn |> log_in_user(admin) |> live(~p"/units/#{unit.unit_id}")

      assert has_element?(view, "#edit-stats-form")
      assert has_element?(view, "input[name='mass']")
      assert has_element?(view, "input[name='energy']")
      assert has_element?(view, "input[name='build_time']")
      assert has_element?(view, "input[name='reason']")
      assert has_element?(view, "button", "Update Stats")
    end

    test "non-admin does not see edit form", %{conn: conn, non_admin: non_admin, unit: unit} do
      {:ok, view, _html} = conn |> log_in_user(non_admin) |> live(~p"/units/#{unit.unit_id}")

      refute has_element?(view, "#edit-stats-form")
    end

    test "admin can update unit stats with reason", %{conn: conn, admin: admin, unit: unit} do
      {:ok, view, _html} = conn |> log_in_user(admin) |> live(~p"/units/#{unit.unit_id}")

      assert render_submit(view, "update_stats", %{
               "mass" => "60",
               "energy" => "550",
               "build_time" => "300",
               "reason" => "Balance update"
             }) =~ "60"

      # Verify the unit was updated
      updated_unit = Units.get_unit!(unit.id)
      assert updated_unit.build_cost_mass == 60
      assert updated_unit.build_cost_energy == 550
      assert updated_unit.build_time == 300
    end

    test "admin cannot update without reason", %{conn: conn, admin: admin, unit: unit} do
      {:ok, view, _html} = conn |> log_in_user(admin) |> live(~p"/units/#{unit.unit_id}")

      html =
        render_submit(view, "update_stats", %{
          "mass" => "60",
          "energy" => "550",
          "build_time" => "300",
          "reason" => ""
        })

      assert html =~ "Reason is required"
    end
  end

  describe "Edit history" do
    setup %{conn: conn} do
      {:ok, admin} =
        Accounts.register_oauth_user(%{
          email: "admin@example.com",
          provider: "github",
          provider_uid: "12345",
          name: "Admin User"
        })

      {:ok, super_admin} =
        Accounts.register_oauth_user(%{
          email: "zwpdbh@outlook.com",
          provider: "github",
          provider_uid: "4442806",
          name: "Super Admin"
        })

      Accounts.grant_admin_role(admin.id, super_admin.id)

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

      %{conn: conn, admin: admin, unit: unit}
    end

    test "displays edit history on unit page", %{conn: conn, admin: admin, unit: unit} do
      # Make an edit
      {:ok, view, _html} = conn |> log_in_user(admin) |> live(~p"/units/#{unit.unit_id}")

      render_submit(view, "update_stats", %{
        "mass" => "60",
        "energy" => "550",
        "build_time" => "300",
        "reason" => "Balance update"
      })

      # Reload the page and check for edit history
      {:ok, _view, html} = conn |> log_in_user(admin) |> live(~p"/units/#{unit.unit_id}")

      assert html =~ "Edit History"
      assert html =~ "50"
      assert html =~ "60"
      assert html =~ "Balance update"
    end
  end
end
