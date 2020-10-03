defmodule Puzzlespace.OrganizationManagement do
  use Puzzlespace.Permissions
  alias Puzzlespace.Mailbox
  alias Puzzlespace.Entity
  alias Puzzlespace.Organization, as: Org
  alias Puzzlespace.Permissions.Prototype

  def found_org(%Entity{} = founder, name) do
    case Org.found_org(founder.id,name) do
      {:ok,multi} -> {:ok, multi.create_org}
      _ -> {:error, "Failed to create Org"}
    end
  end
  
  def invite_player(%Entity{} = inviter,%Entity{} = org, %Entity{} = invitee,title) do
    if_permitted(inviter,org,["manage","grant_title",title]) do
      Mailbox.send_invite(inviter.id,invitee.id,org.id,title)
    end
  end

  def adopt_structure(%Entity{} = user, %Entity{} = org, template) when is_binary(template) do
    if_permitted(user,org,["admin","create_title"]) do
      with {:error, _} <- Prototype.use_preset_structure(org.id,template),
           {:ok,template_org} <- Org.from_name(template),
           {:error,_} <- Relationship.inherit_structure(template_org.entity_id,org.id)
      do
        {:error,"Failed to adopt #{template}"}
      end
    end
  end
end
