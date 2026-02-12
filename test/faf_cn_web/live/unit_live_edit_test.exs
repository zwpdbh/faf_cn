defmodule FafCnWeb.UnitLiveEditTest do
  use FafCnWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias FafCn.Accounts
  alias FafCn.Units

  setup do
    # Set up super admin env vars for tests
    System.put_env("SUPER_ADMIN_EMAIL", "superadmin@example.com")
    System.put_env("SUPER_ADMIN_GITHUB_ID", "99999")

    on_exit(fn ->
      System.delete_env("SUPER_ADMIN_EMAIL")
      System.delete_env("SUPER_ADMIN_GITHUB_ID")
    end)

    :ok
  end

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
          email: "superadmin@example.com",
          provider: "github",
          provider_uid: "99999",
          name: "Super Admin"
        })

      Accounts.grant_admin_role(admin.id, super_admin.id)

      {:ok, non_admin} =
        Accounts.register_oauth_user(%{
          email: "user@example.com",
          provider: "github",
          provider_uid: "88888",
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

      %{conn: conn, admin: admin, super_admin: super_admin, non_admin: non_admin, unit: unit}
    end

    test "super admin sees edit button and can access edit form", %{
      conn: conn,
      super_admin: super_admin,
      unit: unit
    } do
      {:ok, view, _html} = conn |> log_in_user(super_admin) |> live(~p"/units/#{unit.unit_id}")

      # Should see the Edit button
      assert has_element?(view, "button", "Edit")

      # Click edit to enter edit mode
      html = render_click(view, "toggle_edit_mode")

      # Now the form should be visible
      assert html =~ "id=\"edit-stats-form\""
      assert html =~ "name=\"mass\""
      assert html =~ "Update Stats"
    end

    test "admin sees edit button and can access edit form", %{
      conn: conn,
      admin: admin,
      unit: unit
    } do
      {:ok, view, _html} = conn |> log_in_user(admin) |> live(~p"/units/#{unit.unit_id}")

      # Should see the Edit button
      assert has_element?(view, "button", "Edit")

      # Click edit to enter edit mode
      html = render_click(view, "toggle_edit_mode")

      # Now the form should be visible
      assert html =~ "id=\"edit-stats-form\""
      assert html =~ "name=\"mass\""
      assert html =~ "name=\"energy\""
      assert html =~ "name=\"build_time\""
      assert html =~ "name=\"reason\""
      assert html =~ "Update Stats"
    end

    test "non-admin does not see edit button", %{conn: conn, non_admin: non_admin, unit: unit} do
      {:ok, view, _html} = conn |> log_in_user(non_admin) |> live(~p"/units/#{unit.unit_id}")

      refute has_element?(view, "button", "Edit")
    end

    test "admin can update unit stats with reason", %{conn: conn, admin: admin, unit: unit} do
      {:ok, view, _html} = conn |> log_in_user(admin) |> live(~p"/units/#{unit.unit_id}")

      # Enter edit mode
      render_click(view, "toggle_edit_mode")

      html =
        render_submit(view, "update_stats", %{
          "mass" => "60",
          "energy" => "550",
          "build_time" => "300",
          "reason" => "Balance update"
        })

      assert html =~ "60"

      # Verify the unit was updated
      updated_unit = Units.get_unit!(unit.id)
      assert updated_unit.build_cost_mass == 60
      assert updated_unit.build_cost_energy == 550
      assert updated_unit.build_time == 300
    end

    test "admin cannot update without reason", %{conn: conn, admin: admin, unit: unit} do
      {:ok, view, _html} = conn |> log_in_user(admin) |> live(~p"/units/#{unit.unit_id}")

      # Enter edit mode
      render_click(view, "toggle_edit_mode")

      html =
        render_submit(view, "update_stats", %{
          "mass" => "60",
          "energy" => "550",
          "build_time" => "300",
          "reason" => ""
        })

      assert html =~ "Reason is required"
    end

    test "admin can cancel edit mode", %{conn: conn, admin: admin, unit: unit} do
      {:ok, view, _html} = conn |> log_in_user(admin) |> live(~p"/units/#{unit.unit_id}")

      # Enter edit mode
      html = render_click(view, "toggle_edit_mode")
      assert html =~ "id=\"edit-stats-form\""

      # Cancel edit
      html = render_click(view, "cancel_edit")

      # Form should be hidden, stats display visible
      refute html =~ "id=\"edit-stats-form\""
      assert html =~ "Edit"
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
          email: "superadmin@example.com",
          provider: "github",
          provider_uid: "99999",
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

    test "displays edit history when in edit mode", %{conn: conn, admin: admin, unit: unit} do
      # Make an edit
      {:ok, view, _html} = conn |> log_in_user(admin) |> live(~p"/units/#{unit.unit_id}")

      # Enter edit mode and submit
      render_click(view, "toggle_edit_mode")

      render_submit(view, "update_stats", %{
        "mass" => "60",
        "energy" => "550",
        "build_time" => "300",
        "reason" => "Balance update"
      })

      # Reload the page and enter edit mode to see edit history
      {:ok, view, _html} = conn |> log_in_user(admin) |> live(~p"/units/#{unit.unit_id}")

      # Edit history is not visible when not in edit mode
      html = render(view)
      refute html =~ "Edit History"

      # Enter edit mode to see edit history
      html = render_click(view, "toggle_edit_mode")

      assert html =~ "Edit History"
      assert html =~ "50"
      assert html =~ "60"
      assert html =~ "Balance update"
    end
  end
end
