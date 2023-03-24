defmodule Mobilizon.GraphQL.Schema.Actors.MemberType do
  @moduledoc """
  Schema representation for Member
  """
  use Absinthe.Schema.Notation

  alias Mobilizon.GraphQL.Resolvers.{Group, Member}

  @desc """
  Represents a member of a group
  """
  object :member do
    meta(:authorize, :user)
    interfaces([:activity_object])
    field(:id, :id, description: "The member's ID")
    field(:parent, :group, description: "Of which the profile is member")
    field(:actor, :person, description: "Which profile is member of")
    field(:role, :member_role_enum, description: "The role of this membership")
    field(:invited_by, :person, description: "Who invited this member")
    field(:inserted_at, :naive_datetime, description: "When was this member created")
    field(:updated_at, :naive_datetime, description: "When was this member updated")
  end

  @desc """
  Values for a member role
  """
  enum :member_role_enum do
    value(:not_approved, description: "The member needs to be approved by the group admins")
    value(:invited, description: "The member has been invited")
    value(:member, description: "Regular member")
    value(:moderator, description: "The member is a moderator")
    value(:administrator, description: "The member is an administrator")
    value(:creator, description: "The member was the creator of the group. Shouldn't be used.")
    value(:rejected, description: "The member has been rejected or excluded from the group")
  end

  @desc """
  A paginated list of members
  """
  object :paginated_member_list do
    meta(:authorize, :user)
    field(:elements, list_of(:member), description: "A list of members")
    field(:total, :integer, description: "The total number of elements in the list")
  end

  object :member_mutations do
    @desc "Join a group"
    field :join_group, :member do
      arg(:group_id, non_null(:id), description: "The group ID")

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Actors.Member,
        rule: :"write:group_membership",
        args: %{parent_id: :group_id}
      )

      resolve(&Group.join_group/3)
    end

    @desc "Leave a group"
    field :leave_group, :deleted_object do
      arg(:group_id, non_null(:id), description: "The group ID")

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Actors.Member,
        rule: :"write:group_membership",
        args: %{parent_id: :group_id}
      )

      resolve(&Group.leave_group/3)
    end

    @desc "Accept an invitation to a group"
    field :accept_invitation, :member do
      arg(:id, non_null(:id), description: "The member ID")

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Actors.Member,
        rule: :"write:group_membership"
      )

      resolve(&Member.accept_invitation/3)
    end

    @desc "Reject an invitation to a group"
    field :reject_invitation, :member do
      arg(:id, non_null(:id), description: "The member ID")

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Actors.Member,
        rule: :"write:group_membership"
      )

      resolve(&Member.reject_invitation/3)
    end

    @desc "Invite an actor to join the group"
    field :invite_member, :member do
      arg(:group_id, non_null(:id), description: "The group ID")

      arg(:target_actor_username, non_null(:string),
        description: "The targeted person's federated username"
      )

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Actors.Member,
        rule: :"write:group:members",
        args: %{parent_id: :group_id}
      )

      resolve(&Member.invite_member/3)
    end

    @desc """
    Approve a membership request
    """
    field :approve_member, :member do
      arg(:member_id, non_null(:id), description: "The member ID")

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Actors.Member,
        rule: :"write:group:members",
        args: %{parent_id: :member_id}
      )

      resolve(&Member.approve_member/3)
    end

    @desc """
    Reject a membership request
    """
    field :reject_member, :member do
      arg(:member_id, non_null(:id), description: "The member ID")

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Actors.Member,
        rule: :"write:group:members",
        args: %{parent_id: :member_id}
      )

      resolve(&Member.reject_member/3)
    end

    @desc """
    Update a member's role
    """
    field :update_member, :member do
      arg(:member_id, non_null(:id), description: "The member ID")
      arg(:role, non_null(:member_role_enum), description: "The new member role")

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Actors.Member,
        rule: :"write:group:members",
        args: %{parent_id: :member_id}
      )

      resolve(&Member.update_member/3)
    end

    @desc "Remove a member from a group"
    field :remove_member, :member do
      arg(:member_id, non_null(:id), description: "The member ID")

      arg(:exclude, :boolean,
        default_value: false,
        description: "Whether the member should be excluded from the group"
      )

      middleware(Rajska.QueryAuthorization,
        permit: :user,
        scope: Mobilizon.Actors.Member,
        rule: :"write:group:members",
        args: %{parent_id: :member_id}
      )

      resolve(&Member.remove_member/3)
    end
  end
end
