defmodule FafCn.UnitComments.UnitCommentTest do
  use FafCn.DataCase, async: true

  alias FafCn.Accounts
  alias FafCn.UnitComments.UnitComment
  alias FafCn.Units

  describe "unit_comments schema" do
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
        user_id: user.id,
        content: "This is a great unit!"
      }

      assert %Ecto.Changeset{valid?: true} = UnitComment.changeset(%UnitComment{}, attrs)
    end

    test "changeset requires content", %{user: user, unit: unit} do
      attrs = %{
        unit_id: unit.id,
        user_id: user.id
      }

      changeset = UnitComment.changeset(%UnitComment{}, attrs)
      assert "can't be blank" in errors_on(changeset).content
    end

    test "changeset validates content minimum length", %{user: user, unit: unit} do
      attrs = %{
        unit_id: unit.id,
        user_id: user.id,
        content: ""
      }

      changeset = UnitComment.changeset(%UnitComment{}, attrs)
      assert "can't be blank" in errors_on(changeset).content
    end

    test "changeset validates content maximum length", %{user: user, unit: unit} do
      attrs = %{
        unit_id: unit.id,
        user_id: user.id,
        content: String.duplicate("a", 5001)
      }

      changeset = UnitComment.changeset(%UnitComment{}, attrs)
      assert "should be at most 5000 character(s)" in errors_on(changeset).content
    end
  end
end
