defmodule Puzzlespace.PuzzleLogicServerInterface do
  
  def start(puzzle) do
     spawn fn -> init(puzzle) end
  end

  def stop(pserver) do
    send(pserver,{:ingress,:kill})
  end

  def puzzle_lifespan(pserver) do
    new_game(pserver)
    {:ok,dl} = draw(pserver) 
    {:ok,sd} = get_savedata(pserver)
    {dl,sd}
  end

  def puzzle_lifespan(pserver,savedata) do
    set_savedata(pserver,savedata)
    {:ok,dl} = draw(pserver)
    {:ok,sd} = get_savedata(pserver)
    {dl,sd}
  end

  def new_game(pserver) do
    send(pserver,{:ingress,:new})
  end

  def draw(pserver) do
    send(pserver,{:ingress,:draw})
    send(pserver,{:egress,:draw,:to,self()})
    receive do
      {:draw,:ok,list} ->{:ok,list}
      {:draw,:error} -> {:error, "agent timeout"}
    after
      1000 -> {:error, "client timeout"}
    end
  end

  def user_input(pserver,x,y,button) do
    send(pserver,{:ingress,{:input, {x,y,button}}})
  end

  def set_savedata(pserver,savedata) do
    send(pserver,{:ingress,{:load,savedata}})
  end

  def get_savedata(pserver) do
    send(pserver,{:ingress,:save})
    send(pserver,{:egress,:save,:to,self()})
    receive do
      {:save,:ok,savedata} -> {:ok,savedata}
      {:save,:error} -> {:error, "agent timeout"}
    after
      1000 -> {:error, "client timeout"}
    end
  end

  defp init (puzzle) do
    port = Port.open({:spawn,"#{puzzle}_logic_server.exe"},[:binary,{:line,1_000_000}])
    listen(port)
  end

  defp listen(port) do
    listen(port,true)
  end

  defp listen(port,loop) do
    cont = receive do 
      {^port, {:data, {:eol, content} }} -> 
        portside_comms(content,port)
        true
      {^port, :closed} -> false
      {:EXIT,^port,_reason} -> false
      {:ingress,data} -> 
        inbound_comms(data,port)
        true
      {:egress,data,:to,pid} -> 
        outbound_comms(data,pid,port)
        true
      :kill -> 
        false
    end
    if cont and loop do 
      listen(port,true)
    end
  end

  defp outbound_comms(:draw,pid,port) do
    receive do
      {:draw,list} -> send(pid,{:draw,:ok,list})
    after 
      0 -> :noblock
    end
    listen(port,false)
    outbound_comms(:draw,pid,port)
  end

  defp outbound_comms(:save,pid,port) do
    receive do
      {:save,savefile} -> send(pid,{:save,:ok,savefile})
    after
      0 -> :noblock
    end
    listen(port,false)
    outbound_comms(:save,pid,port)
  end 

  defp inbound_comms(:new,port) do
    send(port,{self(),{:command, "NEW\n"}})
  end

  defp inbound_comms(:draw,port) do
    send(port,{self(),{:command, "DRAW\n"}})
  end

  defp inbound_comms(:save,port) do
    send(port,{self(),{:command, "SAVE\n"}})
  end

  defp inbound_comms({:load,data},port) do
    send(port,{self(),{:command,"LOAD\n"}})
    send(port,{self(),{:command,data <> "\n"}})
  end
  
  defp inbound_comms({:input,{x,y,button}},port) do
    send(port,{self(),{:command,"INPUT\n"}})
    send(port,{self(),{:command,"x: #{x}, y: #{y}, button: #{button}"}})
  end

  defp inbound_comms(:kill,port) do
    send(port,{self(),{:command, "KILL\n"}})
    send(port,:kill)
  end

  defp portside_comms("ECHO" <> _rest,_port) do
  end

  defp portside_comms("DRAW\t" <> drawdata,_port) do
    send(self(), {:draw, String.split(drawdata,"\t")})
  end
  
  defp portside_comms("SAVE\t" <> savefile,_port) do
    send(self(), {:save, savefile})
  end

  defp portside_comms("SERVER STARTING",_port) do
  end

  defp portside_comms("get_random_seed",port) do
    send(port,{self(), {:command,(:crypto.strong_rand_bytes(64) |> Base.url_encode64 |> binary_part(0,64)) <>"\n"}})
  end
  
  defp portside_comms("activate_timer",_port) do
  end

  defp portside_comms("deactivate_timer",_port) do
  end

  defp portside_comms("frontend_default_colour",_port) do
  end

  defp portside_comms(_other,_port) do
  end
end
