defmodule FafCn.UnitEditLogs.UnitEditLogTest do
  use FafCn.DataCase, async: true

  alias FafCn.Accounts
  alias FafCn.UnitEditLogs.UnitEditLog
  alias FafCn.Units

  describe "unit_edit_logs schema" do
    setup do
      {:ok, user} =
        Accounts.register_oauth_user(%{
          email: "test@example.com",
          provider: "github",
          provider_uid: "12345",
          name: "Test User"
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

      %{user: user, unit: unit}
    end

    test "changeset with valid attributes", %{user: user, unit: unit} do
      attrs = %{
        unit_id: unit.id,
        field: "build_cost_mass",
        old_value: "50",
        new_value: "60",
        reason: "Balance update",
        edited_by_id: user.id
      }

      assert %Ecto.Changeset{valid?: true} = UnitEditLog.changeset(%UnitEditLog{}, attrs)
    end

    test "changeset requires unit_id", %{user: user} do
      attrs = %{
        field: "build_cost_mass",
        edited_by_id: user.id
      }

      changeset = UnitEditLog.changeset(%UnitEditLog{}, attrs)
      assert "can't be blank" in errors_on(changeset).unit_id
    end

    test "changeset requires field", %{user: user, unit: unit} do
      attrs = %{
        unit_id: unit.id,
        edited_by_id: user.id
      }

      changeset = UnitEditLog.changeset(%UnitEditLog{}, attrs)
      assert "can't be blank" in errors_on(changeset).field
    end

    test "changeset requires edited_by_id", %{unit: unit} do
      attrs = %{
        unit_id: unit.id,
        field: "build_cost_mass"
      }

      changeset = UnitEditLog.changeset(%UnitEditLog{}, attrs)
      assert "can't be blank" in errors_on(changeset).edited_by_id
    end

    test "changeset allows optional values", %{user: user, unit: unit} do
      attrs = %{
        unit_id: unit.id,
        field: "build_cost_mass",
        edited_by_id: user.id
      }

      changeset = UnitEditLog.changeset(%UnitEditLog{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).reason
    end
  end
end
