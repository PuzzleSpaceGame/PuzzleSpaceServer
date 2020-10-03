defmodule PuzzlespaceWeb.STPuzzChannel do
  use Phoenix.Channel
  alias Puzzlespace.Permissions

  @impl true
  def join("stpuzz:" <> slotid, _message, socket) do
    {:ok,slot} = Puzzlespace.SaveSlot.from_id(slotid)
    case Permissions.request_permission(socket.assigns.user.user_entity,slot.owner,["puzzle","access_saveslot",slotid]) do
      {:denied,reason} -> {:error, %{reason: reason}}
      :granted -> {:ok,assign(socket,:slotid,slotid)}
    end
  end

  @impl true
  def handle_in("user_input",%{"body" => body},socket) do
    {:ok,%{"user_input"=>input}} = Jason.decode(body)
    IO.inspect(input)
    {:ok,user} = Puzzlespace.User.from_id(socket.assigns.user.id)
    {:ok,slot} = Puzzlespace.SaveSlot.from_id(socket.assigns.slotid)
    {:ok,draw} = Puzzlespace.Puzzles.update(user.user_entity,slot,input)
    broadcast!(socket, "draw_update",%{body: draw})
    {:noreply,socket}
  end


end
