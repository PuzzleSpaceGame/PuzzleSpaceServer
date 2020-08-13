defmodule Puzzlespace.SessionHandler do
  use GenServer
  alias Puzzlespace.AuthToken

  def get_authenticated_user(token,cache) do
    GenServer.call(cache,{:check,token})
    |> case do
      {:ok, uid} -> uid
      {:error, _} -> nil
    end
  end

  def start_link(_) do
    GenServer.start_link(Puzzlespace.SessionHandler,%{},name: __MODULE__)
  end

  @impl true
  def init(opts) do
    :ets.new(:active_sessions, [:set,:private,:named_table])
    {:ok,opts}
  end

  @impl true
  def handle_call({:check,token},_from,opts) do
    :ets.lookup(:active_sessions,token)
    |> case do
      [] -> #Cache Miss
        case AuthToken.get_user(token) do
          {:ok,uid} -> 
            :ets.insert(:active_sessions,{token,uid})
            {:reply,{:ok,uid},opts}
          error -> {:reply,error,opts}
        end
      [{^token,uid}] ->
        {:reply,{:ok,uid},opts}
      end
  end

  @impl true
  def handle_info(:purge,opts) do
    :ets.foldr(
      fn {token,_uid},acc ->
        case AuthToken.get_user(token) do
          {:error,_} -> 
            :ets.delete(:active_sessions,token)
            acc+1
          {:ok, _} ->
            acc
        end
      end,0,:active_sessions)
    Process.send_after(self(),:purge,60*60*1000)
    {:noreply,opts}
  end
end
