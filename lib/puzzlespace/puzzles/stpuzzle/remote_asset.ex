defmodule Puzzlespace.RemoteAsset do

  defmacro __using__([]) do
    quote do
      @behaviour Puzzlespace.RemoteAsset.RABehaviour
    end
  end

  defmodule RABehaviour do
    @callback ping(pid) :: {:ok,integer()} | :down
    @callback auxilliary_info(pid) :: {:ok,map()} | :down | :cache_miss 
  end
end
