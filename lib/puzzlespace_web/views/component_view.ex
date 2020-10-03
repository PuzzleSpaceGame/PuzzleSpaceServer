defmodule PuzzlespaceWeb.ComponentView do
  use PuzzlespaceWeb, :view

  def render_notification(
    %Puzzlespace.Notification{
      id: id,
      sender_id: sender_id,
      reciever_id: reciever_id,
      payload: message
    },
    %Puzzlespace.Entity{} = viewer,
    %Puzzlespace.Entity{} = owner,
    csrf
  ) do
    type = Puzzlespace.Mailbox.Message.type(message)
    body = fn ->
        {:ok,from} = Puzzlespace.User.from_entity_id(sender_id)
        {:ok,to} = Puzzlespace.User.from_entity_id(reciever_id)
      render(PuzzlespaceWeb.ComponentView,"notification.html",
        viewer: viewer,
        owner: owner,
        id: id,
        to: to,
        from: from,
        message: message,
        type: type,
        csrf: csrf
      )
    end
    Puzzlespace.Permissions.conditional(viewer,owner,["mailbox","view",type],body, fn -> "" end)
  end

  def render_relationship(
    %Puzzlespace.Relationship{} = rel,
    direction
  ) do 
    render("relationship.html",
      direction: :grants,
      title: rel.title,
      ebs: case direction do
        :grants -> unpack(Puzzlespace.Entity.represents(rel.reciever))
        :granted -> unpack(Puzzlespace.Entity.represents(rel.primary))
        end
    )
  end

  def unpack({:ok,x}), do: x
  def unpack(_), do: nil

  def render_saveslots(viewer,owner,csrf) do
    owner = Puzzlespace.Repo.preload(owner,:save_slots)
    saveslots = owner.save_slots
    |> Enum.filter(fn ss -> Puzzlespace.Permissions.granted?(viewer,owner,["puzzle","access_saveslot",ss.id]) end)
    create? = Puzzlespace.Permissions.granted?(viewer,owner,["puzzle","create_saveslot"])
    delete? = Puzzlespace.Permissions.granted?(viewer,owner,["puzzle","delete_saveslot"])
    render("entitys_saveslots.html",
      owner: owner,
      tagline: if viewer.id == owner.id do "Your Saveslots" else "#{Puzzlespace.EntityBacked.name(unpack(Puzzlespace.Entity.represents(owner)))}'s Saveslots " end,
      saveslots: saveslots,
      create?: create?,
      delete?: delete?,
      csrf: csrf
    )
  end
end

