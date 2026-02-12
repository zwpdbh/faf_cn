defmodule FafCn.UnitEditLogsTest do
  use FafCn.DataCase, async: false

  alias FafCn.Accounts
  alias FafCn.UnitEditLogs
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

  describe "log_unit_edit/6" do
    setup do
      {:ok, admin} =
        Accounts.register_oauth_user(%{
          email: "admin@example.com",
          provider: "github",
          provider_uid: "12345",
          name: "Admin User"
        })

      # Grant admin role
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

      %{admin: admin, unit: unit}
    end

    test "creates edit log entry", %{admin: admin, unit: unit} do
      assert {:ok, log} =
               UnitEditLogs.log_unit_edit(
                 unit.id,
                 "build_cost_mass",
                 "50",
                 "60",
                 "Balance update",
                 admin.id
               )

      assert log.unit_id == unit.id
      assert log.field == "build_cost_mass"
      assert log.old_value == "50"
      assert log.new_value == "60"
      assert log.reason == "Balance update"
      assert log.edited_by_id == admin.id
    end

    test "returns error without reason", %{admin: admin, unit: unit} do
      assert {:error, _} =
               UnitEditLogs.log_unit_edit(
                 unit.id,
                 "build_cost_mass",
                 "50",
                 "60",
                 "",
                 admin.id
               )
    end
  end

  describe "list_unit_edit_logs/1" do
    setup do
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

      %{admin: admin, unit: unit}
    end

    test "returns edit logs ordered by newest first", %{admin: admin, unit: unit} do
      {:ok, _log1} =
        UnitEditLogs.log_unit_edit(unit.id, "build_cost_mass", "50", "55", "First edit", admin.id)

      Process.sleep(20)

      {:ok, log2} =
        UnitEditLogs.log_unit_edit(
          unit.id,
          "build_cost_mass",
          "55",
          "60",
          "Second edit",
          admin.id
        )

      logs = UnitEditLogs.list_unit_edit_logs(unit.id)
      assert length(logs) == 2
      # Verify logs are ordered by newest first
      [first | _] = logs
      assert first.id == log2.id
      assert first.reason == "Second edit"
    end

    test "returns empty list when no edits", %{unit: unit} do
      assert UnitEditLogs.list_unit_edit_logs(unit.id) == []
    end
  end

  describe "update_unit_stat/5" do
    setup do
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

      %{admin: admin, non_admin: non_admin, unit: unit}
    end

    test "updates unit stat and creates log when admin", %{admin: admin, unit: unit} do
      assert {:ok, updated_unit} =
               UnitEditLogs.update_unit_stat(
                 unit,
                 "build_cost_mass",
                 "60",
                 "Balance update",
                 admin.id
               )

      assert updated_unit.build_cost_mass == 60

      logs = UnitEditLogs.list_unit_edit_logs(unit.id)
      assert length(logs) == 1
      assert hd(logs).old_value == "50"
      assert hd(logs).new_value == "60"
    end

    test "returns error when non-admin tries to update", %{non_admin: non_admin, unit: unit} do
      assert {:error, "Unauthorized"} =
               UnitEditLogs.update_unit_stat(
                 unit,
                 "build_cost_mass",
                 "60",
                 "Hacked",
                 non_admin.id
               )
    end

    test "returns error without reason", %{admin: admin, unit: unit} do
      assert {:error, %Ecto.Changeset{}} =
               UnitEditLogs.update_unit_stat(
                 unit,
                 "build_cost_mass",
                 "60",
                 "",
                 admin.id
               )
    end

    test "does not create log when value is unchanged", %{admin: admin, unit: unit} do
      # Update with the same value
      assert {:ok, updated_unit} =
               UnitEditLogs.update_unit_stat(
                 unit,
                 "build_cost_mass",
                 "50",
                 "No change",
                 admin.id
               )

      # Unit should be returned unchanged
      assert updated_unit.build_cost_mass == 50

      # No log should be created
      logs = UnitEditLogs.list_unit_edit_logs(unit.id)
      assert logs == []
    end
  end
end
