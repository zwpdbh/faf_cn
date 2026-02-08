defmodule FafCn.UnitComments do
  @moduledoc """
  The UnitComments context.

  Handles CRUD operations for unit comments.
  """

  import Ecto.Query, warn: false
  alias FafCn.Repo
  alias FafCn.UnitComments.UnitComment

  @doc """
  Returns the list of comments for a unit, ordered by newest first.

  ## Examples

      iex> list_unit_comments(unit_id)
      [%UnitComment{}, ...]

  """
  def list_unit_comments(unit_id) do
    UnitComment
    |> where(unit_id: ^unit_id)
    |> order_by([c], desc: c.inserted_at, desc: c.id)
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Gets a single unit_comment.

  Raises `Ecto.NoResultsError` if the Unit comment does not exist.

  ## Examples

      iex> get_unit_comment!(123)
      %UnitComment{}

      iex> get_unit_comment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_unit_comment!(id), do: Repo.get!(UnitComment, id)

  @doc """
  Creates a comment.

  ## Examples

      iex> create_comment(unit_id, user_id, "Great unit!")
      {:ok, %UnitComment{}}

      iex> create_comment(unit_id, user_id, "")
      {:error, %Ecto.Changeset{}}

  """
  def create_comment(unit_id, user_id, content) do
    %UnitComment{}
    |> UnitComment.changeset(%{
      unit_id: unit_id,
      user_id: user_id,
      content: content
    })
    |> Repo.insert()
  end

  @doc """
  Updates a comment. Only the owner can update.

  ## Examples

      iex> update_comment(comment_id, user_id, "Updated content")
      {:ok, %UnitComment{}}

      iex> update_comment(comment_id, other_user_id, "Hacked")
      {:error, "Unauthorized"}

  """
  def update_comment(comment_id, user_id, content) do
    comment = Repo.get(UnitComment, comment_id)

    cond do
      is_nil(comment) ->
        {:error, "Comment not found"}

      comment.user_id != user_id ->
        {:error, "Unauthorized"}

      true ->
        comment
        |> UnitComment.changeset(%{content: content})
        |> Repo.update()
    end
  end

  @doc """
  Deletes a comment. Only the owner can delete.

  ## Examples

      iex> delete_comment(comment_id, user_id)
      :ok

      iex> delete_comment(comment_id, other_user_id)
      {:error, "Unauthorized"}

  """
  def delete_comment(comment_id, user_id) do
    comment = Repo.get(UnitComment, comment_id)

    cond do
      is_nil(comment) ->
        {:error, "Comment not found"}

      comment.user_id != user_id ->
        {:error, "Unauthorized"}

      true ->
        Repo.delete(comment)
        :ok
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking comment changes.

  ## Examples

      iex> change_unit_comment(unit_comment)
      %Ecto.Changeset{data: %UnitComment{}}

  """
  def change_unit_comment(%UnitComment{} = unit_comment, attrs \\ %{}) do
    UnitComment.changeset(unit_comment, attrs)
  end
end
