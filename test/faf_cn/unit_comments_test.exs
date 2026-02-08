defmodule FafCn.UnitCommentsTest do
  use FafCn.DataCase, async: false

  alias FafCn.Accounts
  alias FafCn.UnitComments
  alias FafCn.UnitComments.UnitComment
  alias FafCn.Units

  describe "list_unit_comments/1" do
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

    test "returns comments for a unit ordered by newest first", %{user: user, unit: unit} do
      {:ok, _comment1} = UnitComments.create_comment(unit.id, user.id, "First comment")
      Process.sleep(10)
      {:ok, comment2} = UnitComments.create_comment(unit.id, user.id, "Second comment")

      comments = UnitComments.list_unit_comments(unit.id)
      assert length(comments) == 2
      # First comment should be the newest
      assert hd(comments).content == "Second comment"
      assert hd(comments).id == comment2.id
    end

    test "returns empty list when no comments", %{unit: unit} do
      assert UnitComments.list_unit_comments(unit.id) == []
    end
  end

  describe "create_comment/3" do
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

    test "creates a comment with valid attributes", %{user: user, unit: unit} do
      assert {:ok, %UnitComment{} = comment} =
               UnitComments.create_comment(unit.id, user.id, "Great unit!")

      assert comment.unit_id == unit.id
      assert comment.user_id == user.id
      assert comment.content == "Great unit!"
    end

    test "returns error with empty content", %{user: user, unit: unit} do
      assert {:error, %Ecto.Changeset{}} = UnitComments.create_comment(unit.id, user.id, "")
    end
  end

  describe "update_comment/3" do
    setup do
      {:ok, user} =
        Accounts.register_oauth_user(%{
          email: "test@example.com",
          provider: "github",
          provider_uid: "12345",
          name: "Test User"
        })

      {:ok, other_user} =
        Accounts.register_oauth_user(%{
          email: "other@example.com",
          provider: "github",
          provider_uid: "67890",
          name: "Other User"
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

      {:ok, comment} = UnitComments.create_comment(unit.id, user.id, "Original content")

      %{user: user, other_user: other_user, unit: unit, comment: comment}
    end

    test "updates comment when user is owner", %{user: user, comment: comment} do
      assert {:ok, %UnitComment{} = updated} =
               UnitComments.update_comment(comment.id, user.id, "Updated content")

      assert updated.content == "Updated content"
    end

    test "returns error when user is not owner", %{other_user: other_user, comment: comment} do
      assert {:error, "Unauthorized"} =
               UnitComments.update_comment(comment.id, other_user.id, "Hacked content")
    end

    test "returns error for non-existent comment", %{user: user} do
      assert {:error, "Comment not found"} =
               UnitComments.update_comment(999_999, user.id, "Updated")
    end
  end

  describe "delete_comment/2" do
    setup do
      {:ok, user} =
        Accounts.register_oauth_user(%{
          email: "test@example.com",
          provider: "github",
          provider_uid: "12345",
          name: "Test User"
        })

      {:ok, other_user} =
        Accounts.register_oauth_user(%{
          email: "other@example.com",
          provider: "github",
          provider_uid: "67890",
          name: "Other User"
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

      {:ok, comment} = UnitComments.create_comment(unit.id, user.id, "To be deleted")

      %{user: user, other_user: other_user, unit: unit, comment: comment}
    end

    test "deletes comment when user is owner", %{user: user, unit: unit, comment: comment} do
      assert :ok = UnitComments.delete_comment(comment.id, user.id)
      assert UnitComments.list_unit_comments(unit.id) == []
    end

    test "returns error when user is not owner", %{other_user: other_user, comment: comment} do
      assert {:error, "Unauthorized"} = UnitComments.delete_comment(comment.id, other_user.id)
    end

    test "returns error for non-existent comment", %{user: user} do
      assert {:error, "Comment not found"} = UnitComments.delete_comment(999_999, user.id)
    end
  end
end
