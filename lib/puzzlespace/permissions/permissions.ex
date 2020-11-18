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
  
  def conditional(requester, owner, permission, granted_func, denied_func) do
    case request_permission(requester,owner,permission) do
      :granted -> granted_func.()
      {:denied,_} -> denied_func.()
    end
  end 

  def granted?(requester,owner,permission) do
    conditional(requester,owner,permission, fn -> true end, fn -> false end)
  end

  def request_permission(%Entity{id: rid} = _requester,%Entity{id: oid} = _owner,_permission) when rid == oid do
    :granted
  end

  def request_permission(%Entity{} = requester, %Entity{id: oid}, permission) do
    IO.inspect requester.perm_map
    IO.inspect oid
    with true <- Map.has_key?(requester.perm_map,oid),
         true <- Enum.any?(requester.perm_map[oid],fn perm -> permits(Tuple.to_list(perm),permission) end) do 
      :granted
    else
      false -> {:denied,""}
    end
  end
  
  def request_permission(%Entity{} = _requester,%Entity{} = _owner,_permission) do
    {:denied, ""}
  end

  defp permits(["*" | _], _), do: true
  defp permits([x|_],[y|_]) when x != y, do: false
  defp permits([_|xt],[_|yt]), do: permits(xt,yt)
  defp permits(_,[]), do: true
  defp permits(_,_), do: false

end
