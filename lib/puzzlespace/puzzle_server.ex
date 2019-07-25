defmodule Puzzlespace.PuzzleServer do
  use GenServer , except: [hand_info: 2]
  
  @impl true
  def init(puzzle) do
    case puzzle do
      :bridges -> {:ok, Port.open({:spawn,"bridges_server.exe"},[:binary,{:line,1_000_000}])}
      :loopy -> {:ok, Port.open({:spawn,"loopy_server.exe"},[:binary,{:line,1_000_000}])}
    end
  end
  
  @impl true
  def handle_cast(:new, port) do
    Port.command(port, "NEW\n") |> IO.inspect
    {:noreply,port}
  end
  
  @impl true
  def handle_cast(:kill, port) do
    Port.command(port, "KILL\n")
    Port.command(port, :close)
    {:noreply,port}
  end

  @impl true 
  def handle_cast({:input,x,y,button}, port) do
    Port.command(port,"INPUT\n")
    Port.command(port,"x: #{x}, y: #{y}, button: #{button}\n")
    {:noreply,port}
  end

  @impl true
  def handle_cast({:load,savegame},port) do
    Port.command(port, "LOAD\n")
    Port.command(port, savegame)
    {:noreply,port}
  end

  @impl true
  def handle_call(:draw,_from,port) do
    catcher = Task.async(fn -> 
      data1 = receive do 
        {:data, data} -> data 
      end
      data2 = receive do
        {:data, data} -> data
      end
      {data1,data2}
    end)
    send(port,{self(), {:connect,catcher.pid}})
    send(port,{catcher.pid,{:command, "DRAW\n"}})
    result = Task.await(catcher)
    send(port,{catcher.pid,{:connect,self()}})
    {:reply, result, port}
  end
  
  @impl true
  def handle_call(:save,_from,port) do
    catcher = Task.async(fn -> receive do {:data, data} -> data end end)
    send(port,{self(), {:connect,catcher.pid}})
    send(port,{catcher.pid,{:command, "SAVE\n"}})
    result = Task.await(catcher)
    send(port,{catcher.pid,{:connect,self()}})
    {:reply, result, port}
  end
  
  @impl true
  def handle_info({:data,data},port) do
    case data do
      "SAVEFILE" <> _rest -> send(self(),{:savedata,data})
      "size" <> _rest -> send(self(),{:sizedata,data})
      "start_draw" <> _rest -> send(self(),{:drawdata})
    end
    {:noreply, port}
  end

end
