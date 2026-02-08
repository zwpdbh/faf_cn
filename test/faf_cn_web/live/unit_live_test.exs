defmodule FafCnWeb.UnitLiveTest do
  use FafCnWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias FafCn.Accounts
  alias FafCn.Units
  alias FafCn.UnitComments

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

  describe "Comment editing" do
    setup %{conn: _conn} do
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

      {:ok, owner} =
        Accounts.register_oauth_user(%{
          email: "owner@example.com",
          provider: "github",
          provider_uid: "11111",
          name: "Comment Owner"
        })

      {:ok, other_user} =
        Accounts.register_oauth_user(%{
          email: "other@example.com",
          provider: "github",
          provider_uid: "22222",
          name: "Other User"
        })

      %{unit: unit, owner: owner, other_user: other_user}
    end

    test "owner can edit their own comment", %{conn: conn, owner: owner, unit: unit} do
      # Create a comment first
      {:ok, view, _html} = conn |> log_in_user(owner) |> live(~p"/units/#{unit.unit_id}")

      render_submit(view, "add_comment", %{"content" => "Original comment"})

      # Get the comment ID
      [comment] = UnitComments.list_unit_comments(unit.id)
      comment_id = to_string(comment.id)

      # Check that Edit button is visible
      assert render(view) =~ "Edit"

      # Click Edit button
      html = render_click(view, "edit_comment", %{"comment-id" => comment_id})

      # Should show edit form with textarea
      assert html =~ "save_comment_edit"
      assert html =~ "Original comment"

      # Save the edited comment
      html = render_submit(view, "save_comment_edit", %{"comment-id" => comment_id, "content" => "Updated comment"})

      # Should show updated content
      assert html =~ "Updated comment"
      refute html =~ "Original comment"
    end

    test "owner can cancel editing", %{conn: conn, owner: owner, unit: unit} do
      # Create a comment first
      {:ok, view, _html} = conn |> log_in_user(owner) |> live(~p"/units/#{unit.unit_id}")

      render_submit(view, "add_comment", %{"content" => "My comment"})

      # Get the comment ID
      [comment] = UnitComments.list_unit_comments(unit.id)
      comment_id = to_string(comment.id)

      # Click Edit button
      html = render_click(view, "edit_comment", %{"comment-id" => comment_id})
      assert html =~ "save_comment_edit"

      # Click Cancel
      html = render_click(view, "cancel_edit_comment")

      # Should show original comment
      assert html =~ "My comment"
      refute html =~ "save_comment_edit"
    end

    # Note: Security test for "non-owner cannot edit others' comments" is covered
    # in unit_comments_test.exs - update_comment/3 rejects non-owners
  end
end
