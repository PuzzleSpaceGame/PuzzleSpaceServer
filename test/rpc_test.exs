defmodule RPCTest do
  use ExUnit.Case

  test "rpc not shuffling" do
    outgoing = Enum.map(1..20, fn x -> x end)
    incoming = Parallel.map(outgoing, fn x-> 
      {:ok,x} = Puzzlespace.RemoteAssetHandler.rpc_call(
        STAssetHandler,
        :loopy,
        "ECHOXX~#{x}"
      )
      String.to_integer(x)
    end)
    assert incoming == outgoing
  end
end
