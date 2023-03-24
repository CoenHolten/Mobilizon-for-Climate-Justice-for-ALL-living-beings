defmodule Mobilizon.GraphQL.Schema.MediaType do
  @moduledoc """
  Schema representation for Medias
  """
  use Absinthe.Schema.Notation

  alias Mobilizon.GraphQL.Resolvers.Media

  @env Application.compile_env(:mobilizon, :env)
  @media_rate_limiting 60

  @desc "A media"
  object :media do
    meta(:authorize, :all)
    field(:id, :id, description: "The media's ID")
    field(:alt, :string, description: "The media's alternative text")
    field(:name, :string, description: "The media's name")
    field(:url, :string, description: "The media's full URL")
    field(:content_type, :string, description: "The media's detected content type")
    field(:size, :integer, description: "The media's size")
    field(:metadata, :media_metadata, description: "The media's metadata")
  end

  @desc """
  A paginated list of medias
  """
  object :paginated_media_list do
    meta(:authorize, :all)
    field(:elements, list_of(:media), description: "The list of medias")
    field(:total, :integer, description: "The total number of medias in the list")
  end

  @desc """
  Some metadata associated with a media
  """
  object :media_metadata do
    meta(:authorize, :all)
    field(:width, :integer, description: "The media width (if a picture)")
    field(:height, :integer, description: "The media width (if a height)")
    field(:blurhash, :string, description: "The media blurhash (if a picture")
  end

  @desc "An attached media or a link to a media"
  input_object :media_input do
    # Either a full media object
    field(:media, :media_input_object, description: "A full media attached")
    # Or directly the ID of an existing media
    field(:media_id, :id, description: "The ID of an existing media")
  end

  @desc "An attached media"
  input_object :media_input_object do
    field(:name, non_null(:string), description: "The media's name")
    field(:alt, :string, description: "The media's alternative text")
    field(:file, non_null(:upload), description: "The media file")
    field(:actor_id, :id, description: "The media owner")
  end

  object :media_queries do
    @desc "Get a media"
    field :media, :media do
      arg(:id, non_null(:id), description: "The media ID")
      middleware(Rajska.QueryAuthorization, permit: :all)
      resolve(&Media.media/3)
    end
  end

  object :media_mutations do
    @desc "Upload a media"
    field :upload_media, :media do
      arg(:name, non_null(:string), description: "The media's name")
      arg(:alt, :string, description: "The media's alternative text")
      arg(:file, non_null(:upload), description: "The media file")
      arg(:actor_id, :id, description: "The actor that uploads the media")

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Medias.Media,
        rule: :"write:media:upload",
        args: %{}
      )

      middleware(Rajska.RateLimiter, limit: media_rate_limiting(@env))

      resolve(&Media.upload_media/3)
    end

    @desc """
    Remove a media
    """
    field :remove_media, :deleted_object do
      arg(:id, non_null(:id), description: "The media's ID")

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Medias.Media,
        rule: :"write:media:remove"
      )

      resolve(&Media.remove_media/3)
    end
  end

  defp media_rate_limiting(:test), do: @media_rate_limiting * 1000
  defp media_rate_limiting(_), do: @media_rate_limiting
end
