defmodule Puzzlespace.RemoteAssetHandler do
  use DynamicSupervisor

  def rpc_call(rah_reg,tag,msg) do
    [{task_sup,nil}] = Registry.lookup(rah_reg,RPCTaskSupervisor)
    task = Task.Supervisor.async_nolink(
      task_sup,
      fn -> rpc_call_exec(rah_reg,tag,msg) end
    )
    better_await(task)
  end

  def get_auxilliary_info(rah_reg,tag) do
    [{asset,impl}] = Registry.lookup(rah_reg,{:asset,tag})
    impl.auxilliary_info(asset)
  end

  def list_assets(rah_reg) do
    [{asset_sup,nil}] = Registry.lookup(rah_reg,AssetSupervisor)
    Supervisor.which_children(asset_sup)
    |> Enum.map(
      fn {_,pid,_type,[impl]} ->
        {impl.tag(pid),impl.status(pid)}
      end
    )
  end

  def online_assets(rah_reg) do
    list_assets(rah_reg)
    |> Enum.filter(
      fn {_tag,status} -> status == :up end
    )
    |> Enum.map(
      fn {tag,_status} -> tag end
    )
  end

  defp better_await(task) do
    case Task.yield(task) do
      nil -> better_await(task)
      {:ok, {:ok, result}} -> 
        Task.shutdown(task)
        {:ok, result}
      {:ok, {:error, result}} ->
        Task.shutdown(task)
        {:error,result}
      {:error, reason} -> 
        Task.shutdown(task)
        {:error, reason}
      {:exit,reason} -> 
        Task.shutdown(task)
        {:error,{:exit,reason}}
    end
  end

  defp rpc_call_exec(rah_reg,tag,msg) do 
    try do
      chan = GenServer.call({:via, Registry,{rah_reg, ChannelProvider}},:request)
      case Registry.lookup(rah_reg,{:asset,tag}) do
        [{asset,impl}] -> 
          queue = impl.queue(asset)
          AMQP.Queue.declare(chan, queue)
          inbox = impl.inbox(asset)
          AMQP.Queue.declare(chan, inbox)
          {:ok,consumer_tag} = AMQP.Basic.consume(chan,inbox,nil)
          correlation_id = :rand.uniform(1000000000000000) |> :erlang.integer_to_binary |> Base.encode64
          AMQP.Basic.publish(chan,"",queue,msg,reply_to: inbox,correlation_id: correlation_id)
          {:ok,payload} = await_rpc_response(chan,inbox,correlation_id)
          AMQP.Basic.cancel(chan,consumer_tag)
          AMQP.Channel.close(chan)
          {:ok, payload}
        [] -> {:error,"Asset MIA"}
      end
    rescue
      _ -> {:error,"rpc call failed"}
    end
  end

  defp await_rpc_response(chan,inbox,correlation_id) do
    receive do
      {:basic_deliver,payload,%{delivery_tag: de_tag,correlation_id: ^correlation_id}} -> 
        AMQP.Basic.ack(chan,de_tag)
        {:ok,payload}
      {:basic_deliver,_payload,%{delivery_tag: de_tag}} -> 
        AMQP.Basic.reject(chan,de_tag)
        await_rpc_response(chan,inbox,correlation_id)
      _ ->
        await_rpc_response(chan,inbox,correlation_id)
    end
  end
  
  def start_link(name,connopts,asset_list) do
    {:ok, sup} = DynamicSupervisor.start_link(__MODULE__,{connopts,asset_list,name})
    {:ok,_registry} = DynamicSupervisor.start_child(sup,
      {Registry, [keys: :unique, name: name]}
    )
    {:ok, _} = DynamicSupervisor.start_child(sup,
      {
        Task.Supervisor,
        name: {:via, Registry, {name, RPCTaskSupervisor}},
      }
    )
    {:ok, _} = DynamicSupervisor.start_child(sup,
      %{
        id: ChannelProvider, 
        start: {Puzzlespace.RemoteAssetHandler.ChannelProvider, :start_link, [connopts,{:via, Registry, {name, ChannelProvider}}]}
      }
    )
    {:ok, asset_sup} = DynamicSupervisor.start_child(sup,
      {
        DynamicSupervisor, strategy: :one_for_one,
        name: {:via, Registry, {name, AssetSupervisor}}
      }
    )
    {:ok, _} = DynamicSupervisor.start_child(sup,
      %{
        id: AssetMonitor, 
        start: { Puzzlespace.RemoteAssetHandler.AssetMonitor, :start_link,[ 
            {asset_list,name,asset_sup}, 
            {:via, Registry, {name, AssetMonitor}}
          ]
        }
      }
    )
  end

  @impl true
  def init({_connopts,_asset_list,_name}) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defmodule ChannelProvider do
    use GenServer

    def start_link(connopts,name) do
      GenServer.start_link(__MODULE__,connopts,name: name)
    end

    @impl true
    def init(connopts) do
      {:ok, conn} = AMQP.Connection.open(connopts)
      {:ok,conn}
    end

    @impl true
    def handle_call(:request,_from,conn) do
      {:ok,chan} = AMQP.Channel.open(conn)
      {:reply,chan,conn}
    end
  end

  defmodule AssetMonitor do
    use GenServer

    def start_link(args,name) do
      GenServer.start_link(__MODULE__,args, name: name)
    end

    @impl true
    def init({asset_list,registry,supervisor}) do
      asset_list
      |> Enum.map(
        fn [tag,impl | args] ->
          DynamicSupervisor.start_child(supervisor,
            %{
              id: tag,
              start: {impl, :start_link, [ [tag|args], {:via, Registry, {registry, {:asset,tag}, impl}}]}
            }
          )
        end
      )
      {:ok,registry}
    end
  end
end
