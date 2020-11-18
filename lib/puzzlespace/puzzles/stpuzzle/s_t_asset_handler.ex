defmodule Puzzlespace.STAssetHandler do 
  alias Puzzlespace.RemoteAssetHandler, as: RAH

  def start_link() do
    connopts = Application.get_env(STAssetHandler,:connopts)
    asset_list = Application.get_env(STAssetHandler,:asset_list)
    RAH.start_link(__MODULE__,connopts,asset_list)
  end

  def list_colors(tag) do
    {:ok,%{colors: colors}} = RAH.get_auxilliary_info(STAssetHandler,tag)
    colors
  end
  
  def list_puzzles() do
    RAH.list_assets(STAssetHandler)
  end

  def config(tag) do
    RAH.get_auxilliary_info(STAssetHandler,tag)
    |> assume_ok()
  end

  def new_game(tag,partial_config \\ %{}) do
    cfg = config_msg(tag,partial_config)
          |> assume_ok()
    %{"draw"=>draw,"gamestate"=>gamestate} = 
      RAH.rpc_call(STAssetHandler,tag,"NEWXXX~#{cfg}")
      |> assume_ok()
      |> Jason.decode()
      |> assume_ok()
    {draw,gamestate}
  end

  def update(tag,gamestate,{x,y,b}) do
    %{"draw"=>draw,"gamestate"=>gamestate,"status"=> status} = 
      RAH.rpc_call(STAssetHandler,tag,"UPDATE~#{gamestate}~#{x},#{y},#{b}")
      |> assume_ok()
      |> Jason.decode()
      |> assume_ok()
    {draw,gamestate,status}
  end
  
  def update(tag,gamestate,inputlist) do
    commands = Enum.map(inputlist,&move_desc_to_tuple/1) 
               |> Enum.filter(fn x -> x end)
               |> Enum.map(fn {x,y,b} -> "#{x},#{y},#{b}" end)
    count = length(commands)
    commands = Enum.join(commands,"~")
    %{"draw"=>draw,"gamestate"=>gamestate,"status"=>status} = 
      RAH.rpc_call(STAssetHandler,tag,"BATCHX~#{gamestate}~#{count}~#{commands}")
      |> assume_ok()
      |> Jason.decode()
    {draw,gamestate,status}
  end
  
  def redraw(tag,gamestate) do
    %{"draw"=>draw,"gamestate"=>gamestate,"status"=>status} = 
      RAH.rpc_call(STAssetHandler,tag,"REDRAW~#{gamestate}")
      |> assume_ok()
      |> Jason.decode()
      |> assume_ok()
    {draw,gamestate,status}
  end

  def game_desc(tag,gamestate) do
    %{"game_id" => desc} = RAH.rpc_call(STAssetHandler,tag,"GAMEID~#{gamestate}")
                          |> assume_ok()
                          |> Jason.decode()
                          |> assume_ok()
    desc
  end

  defp assume_ok({:ok,arg}) do
    arg
  end
  
  defp move_desc_to_tuple(%{"pos_x"=>_x,"pos_y"=>_y,"buttons"=>["M0"|_],"mouse"=>_mouse}) do
    nil
  end

  defp move_desc_to_tuple(%{"pos_x"=>x,"pos_y"=>y,"buttons"=>buttons,"mouse"=>mouse}) do
    clicked = case Enum.at(buttons,0) do
      "M1" -> 0x200
      "M2" -> 0x202
      "M3" -> 0x203
    end + case mouse do
      "UP" -> 6
      "DOWN" -> 0
      "DRAG" -> 3
    end
    {round(x),round(y),clicked}
  end

  defp move_desc_to_tuple(%{"pos_x"=>x,"pos_y"=>y,"buttons"=>["Arrow"<>dir | _]=buttons}) do
    button = case dir do
      "Up" -> 0x209
      "Down" -> 0x20A
      "Left" -> 0x20B
      "Right" -> 0x20C
    end + case Enum.find(buttons,"CTRL") do
      nil -> 0
      _ -> 0x1000
    end + case Enum.find(buttons,"SHIFT") do
      nil -> 0
      _ -> 0x2000
    end
    {round(x),round(y),button}
  end

  defp move_desc_to_tuple(%{"pos_x"=>x,"pos_y"=>y,"buttons"=>[button | _],"numpad"=>numpad}) do
    button = List.first(String.to_charlist(button)) + case numpad do
                true -> 0x4000
               false -> 0
             end
    {round(x),round(y),button}
  end
  
  defp config_msg(tag,partial \\ %{}) do
    {:ok,%{cfg: opts}} = RAH.get_auxilliary_info(STAssetHandler,tag)
    opts
    |> Enum.to_list()
    |> Enum.sort_by(fn {_,x} -> x["idx"] end)
    |> Enum.map(
      fn {name,x} ->
        val = partial[name] || x["default"]
        case x["type"] do
          "choices" -> Enum.find_index(x["choices"],&(&1 == val))
          "string" -> val
          "boolean" -> 
            case val do
              true -> 1
              false -> 0
              _ -> val
            end
        end
      end)
    cond do
      Enum.all?(opts) -> {:ok,Enum.join(opts,",")}
      true -> {:error,"incomplete config"}
    end
  end

  defmodule STAsset do
    use GenServer
    use Puzzlespace.RemoteAsset

    def ping(pid) when is_pid(pid) do
      case GenServer.call(pid,:ping) do
        {:ok,:down} -> :down
        {:ok,time} -> time
        {:error,_} -> :down
      end
    end
    def ping(tag) when is_atom(tag), do: ping(tag_to_pid(tag))

    def auxilliary_info(pid) when is_pid(pid)do
      case GenServer.call(pid,:aux_info) do
        {:ok,:cache_miss} -> :cache_miss
        {:ok,info} -> info
        {:error,_} -> :down
      end
    end
    def auxilliary_info(tag) when is_atom(tag), do: auxilliary_info(tag_to_pid(tag))

    def status(pid) when is_pid(pid) do
      case GenServer.call(pid,:status) do
        {:error, _} -> :down
        status -> status
      end
    end
    def status(tag) when is_atom(tag), do: status(tag_to_pid(tag))

    def queue(pid) when is_pid(pid)do
      case GenServer.call(pid,:queue) do
        {:error, _} -> :down
        queue -> queue
      end
    end
    def queue(tag) when is_atom(tag), do: queue(tag_to_pid(tag))

    def tag_to_pid(tag) do
      [{asset_reg,nil}] = Registry.lookup(STAssetHandler,AssetRegistry)
      [{asset,_}] = Registry.lookup(asset_reg,tag)
      asset
    end

    def inbox(_tag) do
      "rpc_response"
    end

    def init([tag,queue,defaults]) do
      Kernel.send(self(),{:update,0})
      {:ok,{tag,:down,queue,%{defaults: defaults}}}
    end

    def handle_call(:ping, from, {tag,status,queue,aux_info}) do
      asset = self()
      _task = Task.async(
        fn -> 
          {time,res} = :timer.tc(
            fn -> RAH.rpc_call(STAssetHandler,tag,"PINGXX") end
          )
          response = case res do
            {:ok,_} -> 
              GenServer.cast(asset,{:status,:up})
              {:ok,time}
            x -> 
              GenServer.cast(asset,{:status,:down})
              x
          end
          GenServer.reply(from,response)
        end
      )
      {:noreply,{tag,status,queue,aux_info}}
    end

    def handle_call(:aux_info,_from,{_tag,_status,_queue,aux_info} = state) do
      {:reply,aux_info,state}
    end

    def handle_call(:queue,_from,{_tag,_status,queue,_aux_info} = state) do
      {:reply,queue,state}
    end

    def handle_call(:status,_from,{_tag,status,_queue,_aux_info} = state) do
      {:reply,status,state}
    end

    def handle_cast({:status,new_status},{tag,_old_status,queue,aux_info}) do
      {:noreply,{tag,new_status,queue,aux_info}}
    end

    def handle_cast({:aux_info,:cache_miss},{tag,status,queue,info}) do
      {:noreply,{tag,status,queue,info}}
    end
    def handle_cast({:aux_info,new_info},{tag,status,queue,old_info}) do 
      updated_info = case old_info do
        %{} = info -> info
        _ -> %{}
      end
      |> Map.merge(new_info)
      {:noreply,{tag,status,queue,updated_info}}
    end

    def handle_info({:update,0},{tag,_status,_queue,aux_info} = state) do
      asset = self()
      _cfg_task = Task.async(
        fn -> 
          {:ok,rawcfg} = RAH.rpc_call(STAssetHandler,tag,"GETCFG")      
          cfg = rawcfg
          |> Jason.decode() 
          |> case do
            {:ok,%{"opts" => rawopts}} ->
              rawopts
              |> Enum.map(fn opt ->
                  case opt do
                    %{"type" => "string"} ->
                      opt
                    %{"type" => "choices", "choices" => choices, "name"=>name} ->
                      %{
                        "name" => name,
                        "type" => "choices",
                        "choices" => String.split(choices,String.at(choices,0),trim: true)
                      }
                    %{"type" => "boolean"} ->
                      opt
                  end
              end)
              |> Enum.with_index()
              |> Enum.map(
                fn {config,idx} ->
                  config = Map.new(config)
                           |> Map.put("idx",idx)
                  name = config["name"]
                  case aux_info[:defaults] do
                    %{^name=>def_val} ->
                      Map.put(config,"default",def_val)
                    _ -> config
                  end
                end)
              |> Map.new(fn x -> {x["name"],x} end)
            _ -> :cache_miss
          end
          case cfg do
            :cache_miss -> GenServer.cast(asset,{:aux_info,:cache_miss})
            _ -> GenServer.cast(asset,{:aux_info,%{cfg: cfg}})
          end
        end
      )

      _color_task = Task.async(
        fn -> 
          {:ok,rawcolors} = RAH.rpc_call(STAssetHandler,tag,"COLORS")
          colors = rawcolors
          |> Jason.decode()
          |> case do
            {:ok,%{"colours" => colors}} ->
              colors
            _ -> :cache_miss
          end
          case colors do
            :cache_miss -> GenServer.cast(asset,{:aux_info,:cache_miss})
            _ -> GenServer.cast(asset,{:aux_info,%{colors: colors}})
          end
        end
      )
      ping(self())
      Process.send_after(self(),{:update,12},1000*60*5)
      {:noreply,state}
    end
    def handle_info({:update,counter},state) do
      ping(self())
      Process.send_after(self(),{:update,counter - 1},1000*60*5)
      {:noreply,state}
    end 
  end
end
