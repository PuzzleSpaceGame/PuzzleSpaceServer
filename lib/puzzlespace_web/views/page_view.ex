defmodule PuzzlespaceWeb.PageView do
  use PuzzlespaceWeb, :view
  alias Puzzlespace.Permissions

  def render_perm(perm) do
    Tuple.to_list(perm)
    |> Enum.join(":")
  end
  
  def render_mailbox(requester_entity,owner_entity,csrf) do
    body = fn -> 
      inbox = Puzzlespace.Notification.get_recieved(owner_entity)
      outbox = Puzzlespace.Notification.get_sent(owner_entity)
      render(PuzzlespaceWeb.ComponentView,"mailbox.html",
        inbox: inbox,
        outbox: outbox,
        viewer: requester_entity,
        owner: owner_entity,
        csrf: csrf
      )
    end
    Permissions.conditional(requester_entity,owner_entity,["mailbox","view"],body, fn -> "" end)
  end

  def render_titles(entity) do
    entity = Puzzlespace.Repo.preload(entity,[:granting_relationships,:recieving_relationships])
    grants = entity.granting_relationships |> Puzzlespace.Repo.preload(:reciever) |> Enum.filter( fn rel -> rel.primary_id != rel.reciever_id end)
    recieves = entity.recieving_relationships |> Puzzlespace.Repo.preload(:primary) |> Enum.filter( fn rel -> rel.primary_id != rel.reciever_id end)
    render(PuzzlespaceWeb.ComponentView,"relationships.html",
      recieves: recieves,
      grants: grants
    )
  end
  
  def render_saves(usr_ent,csrf) do
    usr_ent = Puzzlespace.Repo.preload(usr_ent,:recieving_relationships)
    usr_ent.recieving_relationships 
    |> Puzzlespace.Repo.preload(:primary)
    |> Enum.uniq_by(fn rel -> rel.primary_id end)
    |> Enum.map(fn rel -> rel.primary end)
    |> Enum.filter(fn owner -> Puzzlespace.Permissions.granted?(usr_ent,owner,["puzzle","access_saveslots"]) end)
    |> List.insert_at(0,usr_ent)
    |> Enum.map(fn owner -> PuzzlespaceWeb.ComponentView.render_saveslots(usr_ent,owner,csrf) end)
  end

end
