defmodule RPCCoordinator do
  use GenServer

  def establish_connection(impl) do
    {:ok, conn} = 
      Application.get_env(impl,:connopts)
      |> AMQP.Connection.open()
    
    Application.get_env(impl,:queues)
    |> Enum.map(
      fn {tag,queue} -> 
        {:ok, chan} = AMQP.Channel.open(conn)
        AMQP.Queue.declare(chan,queue)
        Supervisor.child_spec(
          {RPCCoordinator.RPCHandler,
            {tag,{impl.get_transform(tag),chan,queue}}
          },
          id: tag
        )
      end)
    |> Supervisor.start_link(strategy: :one_for_one)
  end

  @impl true
  def init(impl) do
    {:ok,establish_connection(impl)}
  end

  @impl true
  def handle_call({tag,msg},from,state) do
    GenServer.cast(tag,{msg,from})
    {:noreply,state}
  end

  @impl true
  def handle_call(_,_from,state) do
    {:reply,:error,state}
  end
  
  @impl true
  def handle_cast(_,state) do
    {:noreply,state}
  end
  
  defmodule RPCHandler do
    use GenServer

    def start_link({tag,args}) do
      GenServer.start_link(__MODULE__,args,name: tag)
    end
    
    @impl true
    def init({transform,chan,outbox}) do
      {:ok,supervisor} = Task.Supervisor.start_link()
      {:ok,%{queue: inbox}} = AMQP.Queue.declare(chan,"#{outbox}_response")
      {:ok,{transform,chan,inbox,outbox,supervisor}}
    end


    def await_rpc_response(chan,inbox,correlation_id) do
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

    @impl true
    def handle_cast({msg,replyto},state = {transform,chan,inbox,outbox,supervisor}) do
      Task.Supervisor.start_child(supervisor,fn ->
        amqp_msg = transform.(msg)
        correlation_id = :erlang.unique_integer |> :erlang.integer_to_binary |> Base.encode64
        {:ok,consumer_tag} = AMQP.Basic.consume(chan,inbox,nil)
        AMQP.Basic.publish(chan,"",outbox,amqp_msg,reply_to: inbox,correlation_id: correlation_id)
        {:ok,payload} = await_rpc_response(chan,inbox,correlation_id)
        AMQP.Basic.cancel(chan,consumer_tag)
        GenServer.reply(replyto,payload)
        :ok
      end)
      {:noreply,state}
    end
  end

end
