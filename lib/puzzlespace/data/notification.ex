defmodule Puzzlespace.Notification do
  use Puzzlespace.Schema
  import Ecto.Changeset
  alias Puzzlespace.Notification
  alias Puzzlespace.Entity
  alias Puzzlespace.Mailbox.EmbeddedMessage, as: EmbeddedMessage

  schema "notifications" do
    belongs_to :sender, Entity
    belongs_to :reciever, Entity
    field :payload, EmbeddedMessage
    timestamps()
  end

  def changeset(%Notification{} = notification, attrs) do
    notification
    |> cast(attrs,[:sender_id,:reciever_id,:payload])
    |> validate_required([:sender_id,:reciever_id,:payload])
  end

  def send_msg(%{sender_id: sender, reciever_id: reciever} = message) do
    Notification.changeset(%Notification{},%{sender_id: sender, reciever_id: reciever, payload: message})
    |> Puzzlespace.Repo.insert()
  end

  def delete(%Notification{} = notif) do
    Puzzlespace.Repo.delete(notif)
  end

  def get_recieved(%Entity{} = entity) do
    entity = Puzzlespace.Repo.preload(entity,:inbox)
    entity.inbox
  end

  def get_sent(%Entity{} = entity) do
    entity = Puzzlespace.Repo.preload(entity,:outbox)
    entity.outbox
  end

  def handle_action(notif_id,"Dismiss") do
    Puzzlespace.Repo.get(Notification,notif_id)
    |> Notification.delete()
  end
  
  def handle_action(notif_id,action) do
    case Puzzlespace.Repo.get(Notification,notif_id) do
      nil -> {:error,"No such message"}
      notif -> 
        Puzzlespace.Mailbox.Message.action(notif.payload,action)
        Puzzlespace.Repo.get(Notification,notif_id)
        |> Notification.delete()
    end
  end
end

