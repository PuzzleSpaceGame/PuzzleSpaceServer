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
    [{asset_reg,nil}] = Registry.lookup(rah_reg,AssetRegistry)
    [{asset,impl}] = Registry.lookup(asset_reg,tag)
    impl.auxilliary_info(asset)
  end

  def list_assets(rah_reg) do
    [{asset_sup,nil}] = Registry.lookup(rah_reg,AssetSupervisor)
    Supervisor.which_children(asset_sup)
    |> Enum.map(
      fn {tag,pid,_type,impl} ->
        {tag,impl.status(pid)}
      end
    )
    |> Enum.filter(
      fn {_tag,status} -> status == :up end
    )
    |> Enum.filter(
      fn {tag,_status} -> tag end
    )
  end

  defp better_await(task) do
    case Task.yield(task) do
      nil -> better_await(task)
      {:ok, {:ok, result}} -> 
        Task.shutdown(task)
        {:ok, result}
      {:error, reason} -> 
        Task.shutdown(task)
        {:error, reason}
      {:exit,reason} -> 
        Task.shutdown(task)
        {:error,{:exit,reason}}
    end
  end

  defp rpc_call_exec(rah_reg,tag,msg) do 
    {:ok,chan} = GenServer.call({:via, Registry,{rah_reg, ChannelProvider}},:request)
    [{asset_reg,nil}] = Registry.lookup(rah_reg,AssetRegistry)
    [{asset,impl}] = Registry.lookup(asset_reg,tag)
    queue = impl.queue(asset)
    AMQP.Queue.declare(chan, queue)
    inbox = impl.inbox(asset)
    AMQP.Queue.declare(chan, inbox)
    {:ok,consumer_tag} = AMQP.Basic.consume(chan,inbox,nil)
    correlation_id = :erlang.unique_integer |> :erlang.integer_to_binary |> Base.encode64
    AMQP.Basic.publish(chan,"",queue,msg,reply_to: inbox,correlation_id: correlation_id)
    {:ok,payload} = await_rpc_response(chan,inbox,correlation_id)
    AMQP.Basic.cancel(chan,consumer_tag)
    {:ok, payload}
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
    DynamicSupervisor.start_link(__MODULE__,{connopts,asset_list,name})
  end

  @impl true
  def init({connopts,asset_list,name}) do
    DynamicSupervisor.init(strategy: :one_for_one)
    {:ok,registry} = DynamicSupervisor.start_child(self(),
      {Registry, keys: :unique, name: name}
    )
    {:ok, _} = DynamicSupervisor.start_child(self(),
      {
        ChannelProvider, [connopts],
        name: {:via, Registry, {registry, ChannelProvider}}
      }
    )
    {:ok, asset_sup} = DynamicSupervisor.start_child(self(),
      {
        DynamicSupervisor, strategy: :one_for_one,
        name: {:via, Registry, {registry, AssetSupervisor}}
      }
    )
    {:ok, asset_reg} = DynamicSupervisor.start_child(self(),
      {
        Registry, keys: :unique, 
        name: {:via, Registry, {registry, AssetRegistry}}
      }
    )
    {:ok, _} = DynamicSupervisor.start_child(self(),
      {
        AssetMonitor, 
        [{asset_list,asset_reg,asset_sup}], 
        name: {:via, Registry, {registry, AssetMonitor}}
      }
    )
    {:ok, _} = DynamicSupervisor.start_child(self(),
      {
        Task.Supervisor,
        name: {:via, Registry, {registry, RPCTaskSupervisor}}
      }
    )
  end

  defmodule ChannelProvider do
    use GenServer

    @impl true
    def init(connopts) do
      {:ok, conn} = AMQP.Connection.open(connopts)
      conn
    end

    @impl true
    def handle_call(:request,_from,conn) do
      {:ok,chan} = AMQP.Channel.open(conn)
      {:reply,chan,conn}
    end
  end

  defmodule AssetMonitor do
    use GenServer

    @impl true
    def init({asset_list,registry,supervisor}) do
      asset_list
      |> Parallel.map(
        fn [tag,impl | args] ->
          DynamicSupervisor.start_child(supervisor,
            {
              impl,[tag|args],
              name: {:via, Registry, {registry, tag, impl}}
            }
          )
        end
      )
      {:ok,registry}
    end
  end
end
