defmodule Mobilizon.GraphQL.API.Comments do
  @moduledoc """
  API for discussions and comments.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Conversations.Conversation
  alias Mobilizon.Discussions.{Comment, Discussion}
  alias Mobilizon.Federation.ActivityPub.{Actions, Activity}
  alias Mobilizon.GraphQL.API.Utils

  @doc """
  Create a comment
  """
  @spec create_comment(map) ::
          {:ok, Activity.t(), Comment.t()}
          | {:error, :entity_tombstoned | atom() | Ecto.Changeset.t()}
  def create_comment(args) do
    args = extract_pictures_from_comment_body(args)
    Actions.Create.create(:comment, args, true)
  end

  @doc """
  Updates a comment
  """
  @spec update_comment(Comment.t(), map()) ::
          {:ok, Activity.t(), Comment.t()} | {:error, atom() | Ecto.Changeset.t()}
  def update_comment(%Comment{} = comment, args) do
    args = extract_pictures_from_comment_body(args)
    Actions.Update.update(comment, args, true)
  end

  @doc """
  Deletes a comment
  """
  @spec delete_comment(Comment.t(), Actor.t()) :: {:ok, Activity.t(), Comment.t()} | any
  def delete_comment(%Comment{} = comment, %Actor{} = actor) do
    Actions.Delete.delete(comment, actor, true)
  end

  @doc """
  Creates a discussion (or reply to a discussion)
  """
  @spec create_discussion(map()) ::
          {:ok, Activity.t(), Discussion.t()}
          | {:error, :entity_tombstoned | atom | Ecto.Changeset.t()}
  def create_discussion(args) do
    args = extract_pictures_from_comment_body(args)

    Actions.Create.create(
      :discussion,
      args,
      true
    )
  end

  @doc """
  Creates a conversation (or reply to a conversation)
  """
  @spec create_conversation(map()) ::
          {:ok, Activity.t(), Conversation.t()}
          | {:error, :entity_tombstoned | atom | Ecto.Changeset.t()}
  def create_conversation(args) do
    args = extract_pictures_from_comment_body(args)

    Actions.Create.create(
      :conversation,
      args,
      true
    )
  end

  @spec extract_pictures_from_comment_body(map()) :: map()
  defp extract_pictures_from_comment_body(%{text: text, actor_id: actor_id} = args) do
    pictures = Utils.extract_pictures_from_body(text, actor_id)
    Map.put(args, :media, pictures)
  end

  defp extract_pictures_from_comment_body(args), do: args
end
