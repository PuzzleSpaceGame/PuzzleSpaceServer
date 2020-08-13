defmodule Puzzlespace.Permissions do
  alias Puzzlespace.Entity

  defmacro if_permitted(requester, owner, permission, do: block) do
    quote do
      case Puzzlespace.Permissions.request_permission(unquote(requester),unquote(owner),unquote(permission)) do
        {:denied,reason} -> {:error,"Permission denied:" <> reason}
        :granted -> {:ok,unquote(block)}
      end
    end
  end


  defmacro __using__(_) do
    quote do
      import Puzzlespace.Permissions, only: [if_permitted: 4]
    end
  end
  
  
  def request_permission(%Entity{id: rid} = _requester,%Entity{id: oid} = _owner,_permission) when rid == oid do
    :granted
  end
  
  def request_permission(%Entity{} = _requester,%Entity{} = _owner,_permission) do
    {:denied, ""}
  end
end
