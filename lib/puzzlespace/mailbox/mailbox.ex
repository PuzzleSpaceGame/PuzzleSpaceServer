defmodule Puzzlespace.Mailbox do
  alias Puzzlespace.Organization, as: Org
  alias Puzzlespace.Relationship
  alias Puzzlespace.Mailbox.InviteMessage
  alias Puzzlespace.Mailbox.TextMessage
  alias Puzzlespace.Message
  alias Puzzlespace.GenericMessage
  alias Puzzlespace.Notification
  alias Puzzlespace.Mailbox

  defprotocol Message do

    @spec to_map(Message.t()) :: Map.t()
    def to_map(message)

    @spec buttons(Message.t()) :: [String.t()]
    def buttons(message)
    def body_text(message)
    def action(message,action)
    def send_msg(message)
    def type(message)
  end
  
  defmodule GenericMessageBehaviour do
    @callback from_map(Map.t()) :: Message.t()
    @callback to_map(Message.t()) :: Map.t()
    @callback send_msg(Message.t()) :: :ok | :error
  end
  
  defmodule GenericMessage do
    defmacro __using__(fields) do
      fields = [:sender_id,:reciever_id | fields]
      quote do
        defstruct unquote(fields)
        @behaviour GenericMessageBehaviour
        
        def from_map(%{"type" => type} = map) do
          map
          |> Enum.filter(fn {key,val} -> key != "type" end)
          |> Enum.map(fn {key,val} -> {String.to_existing_atom(key),val} end)
          |> Map.new()
          |> Map.put(:__struct__, String.to_existing_atom(type))
        end
        def to_map(message) do
          Map.from_struct(message)
          |> Map.put("type",Atom.to_string(message.__struct__))
        end

        def send_msg(message) do
          {status, _} = Notification.send_msg(message)
          status
        end
        defoverridable GenericMessageBehaviour
        
      end
    end

  end

  defmodule EmbeddedMessage do
    use Ecto.Type
    
    @impl true
    def type, do: :map

    @impl true
    def cast(x) do 
      case Message.impl_for(x) do
        nil -> :error
        _ -> {:ok,x}
      end
    end

    @impl true
    def load(%{"type" => type} = data) do
      type = String.to_existing_atom(type)
      {:ok,type.from_map(data)}
    end

    def load(_), do: :error
    @impl true
    def dump(x), do: {:ok, Message.to_map(x)}
  end

  defmodule TextMessage do
    use GenericMessage, [:text]
    defimpl Message do
      def send_msg(message), do: TextMessage.send_msg(message)
      def to_map(message), do: TextMessage.to_map(message)
      def buttons(%TextMessage{}), do: []
      def body_text(%TextMessage{text: text}), do: text
      def action(%TextMessage{},_), do: {:error, "No such action"}
      def type(%TextMessage{}), do: "text"
    end
  end

  defmodule InviteMessage do
    use GenericMessage, [:organization_id,:title]
    defimpl Message do
      def send_msg(message), do: InviteMessage.send_msg(message)
      def to_map(message), do: InviteMessage.to_map(message)
      def buttons(%InviteMessage{}), do: ["accept","decline"]
      def type(%InviteMessage{}), do: "invite"
      def body_text(%InviteMessage{organization_id: org_id, title: title}) do
        {:ok,org} = Org.from_entity_id(org_id)
        "#{org.name} offers you the title of #{title}"
      end
      def action(%InviteMessage{organization_id: org_id, title: title, reciever_id: reciever_id},"accept") do
        Relationship.assign_title(org_id,title,reciever_id)
        :ok
      end
      def action(%InviteMessage{organization_id: org_id} = msg,"decline") do 
        org = Org.from_entity_id(org_id)
        Mailbox.reply(msg,"Declined to join #{org.name}")
        :ok
      end
      def action(%InviteMessage{},_), do: {:error, "No such action"}
    end
  end


  def send_invite(sender_id,invitee_id,org_id,title) do
    %InviteMessage{
      sender_id: sender_id,
      reciever_id: invitee_id,
      organization_id: org_id,
      title: title
    }
    |> Message.send_msg()
  end

  def send_text(from_id, to_id, text) do
    %TextMessage{
      sender_id: from_id,
      reciever_id: to_id,
      text: text
    }
    |> Message.send_msg()
  end

  def reply(%{sender_id: sender_id, reciever_id: reciever_id},text) do
    send_text(reciever_id,sender_id,text)
  end
  
end
