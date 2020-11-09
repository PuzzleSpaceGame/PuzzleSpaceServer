defmodule STPuzzleCoordinator do

  #Client API
  def child_spec(_) do
    %{
      id: STPuzzleCoordinator,
      start: {STPuzzleCoordinator, :initialize, []}
    }
  end

  def initialize() do
    {:ok,_pid} = GenServer.start_link(RPCCoordinator,__MODULE__,name: {:global, __MODULE__})
    {:ok,_pid} = GenServer.start_link(STPuzzleCoordinator.ConfigHandler,{},name: {:global, STPuzzleCoordinator.ConfigHandler})
  end
 
  def get_config(tag) do
    {:ok,%{"opts" => rawopts}} = GenServer.call({:global,__MODULE__},{tag,"GETCFG"})
              |>Jason.decode()
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
  end

  def get_colors(tag) do
    {:ok,%{"colours" => colors}} = GenServer.call({:global,__MODULE__},{tag,"COLORS"})
                                 |> Jason.decode()
    colors
  end

  def list_colors(tag) do
    GenServer.call({:global,STPuzzleCoordinator.ConfigHandler},{:get_colors,tag})
  end

  def config(tag) do
    GenServer.call({:global,STPuzzleCoordinator.ConfigHandler},{:get,tag})
  end

  def list_puzzles() do
    STPuzzleCoordinator.ConfigHandler.list_puzzles()
  end

  def new_game(tag,partial_config \\ %{}) do
    {:ok, cfg} = STPuzzleCoordinator.ConfigHandler.config_msg(tag,partial_config)
    {:ok,%{"draw"=>draw,"gamestate"=>gamestate}} = 
      GenServer.call({:global,__MODULE__},{tag,"NEWXXX~#{cfg}"},:infinity)
      |>Jason.decode
    {draw,gamestate}
  end

  def update(tag,gamestate,{x,y,b}) do
    {:ok,%{"draw"=>draw,"gamestate"=>gamestate,"status"=> status}} = 
      GenServer.call({:global,__MODULE__},{tag,"UPDATE~#{gamestate}~#{x},#{y},#{b}"},:infinity)
      |>Jason.decode
    {draw,gamestate,status}
  end

  def update(tag,gamestate,inputlist) do
    commands = Enum.map(inputlist,&move_desc_to_tuple/1) 
               |> Enum.filter(fn x -> x end)
               |> Enum.map(fn {x,y,b} -> "#{x},#{y},#{b}" end)
    count = length(commands)
    commands = Enum.join(commands,"~")
    {:ok,%{"draw"=>draw,"gamestate"=>gamestate,"status"=>status}} = 
      GenServer.call({:global,__MODULE__},{tag,"BATCHX~#{gamestate}~#{count}~#{commands}"},:infinity)
      |>Jason.decode
    {draw,gamestate,status}
  end


  def move_desc_to_tuple(%{"pos_x"=>_x,"pos_y"=>_y,"buttons"=>["M0"|_],"mouse"=>_mouse}) do
    nil
  end

  def move_desc_to_tuple(%{"pos_x"=>x,"pos_y"=>y,"buttons"=>buttons,"mouse"=>mouse}) do
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

  def move_desc_to_tuple(%{"pos_x"=>x,"pos_y"=>y,"buttons"=>["Arrow"<>dir | _]=buttons}) do
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

  def move_desc_to_tuple(%{"pos_x"=>x,"pos_y"=>y,"buttons"=>[button | _],"numpad"=>numpad}) do
    button = List.first(String.to_charlist(button)) + case numpad do
                true -> 0x4000
               false -> 0
             end
    {round(x),round(y),button}
  end
  def redraw(tag,gamestate) do
    {:ok,%{"draw"=>draw,"gamestate"=>gamestate,"status"=>status}} = 
      GenServer.call({:global,__MODULE__},{tag,"REDRAW~#{gamestate}"},:infinity)
      |>Jason.decode
    {draw,gamestate,status}
  end

  def game_desc(tag,gamestate) do
    {:ok,%{"game_id" => desc}} = GenServer.call({:global,__MODULE__},{tag,"GAMEID~#{gamestate}"})
                                |> Jason.decode()
    desc 
  end

  #Implementation-Specific RPCCoordinator calls
  def get_transform(_) do
    &transform/1
  end

  def transform(x) do
    x
  end

  defmodule ConfigHandler do
    use GenServer
    alias STPuzzleCoordinator.ConfigHandler, as: ConfigHandler

    def list_puzzles() do
      GenServer.call({:global,ConfigHandler},:list)
    end

    def get_colors(tag) do
      GenServer.call({:global,ConfigHandler},{:get_colors,tag})
    end
    
    def config_msg(tag,partial \\ %{}) do
      
      opts = GenServer.call({:global,ConfigHandler},{:get,tag})             
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
    
    @impl true
    def init(_) do
      table = :ets.new(:config_cache,[:set,:public])
      Application.get_env(STPuzzleCoordinator,:queues)
      |> Parallel.map(
        fn {tag,_queue} ->
          defaults = 
            Application.get_env(STPuzzleCoordinator,:default_config)[tag]
          config_desc = STPuzzleCoordinator.get_config(tag)
          |> Enum.with_index()
          |> Enum.map(
            fn {config,idx} ->
              config = Map.new(config)
                       |> Map.put("idx",idx)
              name = config["name"]
              case defaults do
                %{^name=>def_val} ->
                  Map.put(config,"default",def_val)
                _ -> config
              end
            end)
            |> Map.new(fn x -> {x["name"],x} end)
            :ets.insert(table,{tag,config_desc})
        end)
      color_cache = :ets.new(:color_cache,[:set,:public])
      Application.get_env(STPuzzleCoordinator,:queues)
      |> Parallel.map(
        fn {tag,_queue} ->
          colors = STPuzzleCoordinator.get_colors(tag)
          :ets.insert(color_cache,{tag,colors})
        end)
      {:ok,{table,color_cache}}
    end

    @impl true
    def handle_call({:get,tag},_from,{table,colors}) do
      {^tag,resp} = List.first(:ets.lookup(table,tag))
      {:reply,resp,{table,colors}}
    end

    def handle_call(:list,_from,{table,colors}) do
      list = :ets.foldr(fn {key,_},acc -> [key] ++ acc end,[],table)
      {:reply,list,{table,colors}}
    end

    def handle_call({:get_colors,tag},_from,{_table,color_table} = tables) do
      {^tag, colors} = List.first(:ets.lookup(color_table,tag))
      {:reply,colors,tables}
    end
  end
end
