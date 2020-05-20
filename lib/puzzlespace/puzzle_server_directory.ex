defmodule Puzzlespace.PuzzleServerDirectory do 
  alias Puzzlespace.PuzzleLogicServerInterface, as: PLSI
  use GenServer
  
  def start_link(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  def get_server(sd,puzzle) do
    GenServer.call(sd, {:get_server,puzzle})
  end

  @impl true
  def init(_state) do
    {:ok,%{}}
  end

  @impl true
  def handle_call({:get_server,puzzle},_from,state) do
    state = cond do
      state[puzzle] == nil ->
        Map.put(state,puzzle,
          {
            PLSI.start(puzzle), 
            Process.send_after(self(), {:timeout, puzzle}, Application.fetch_env!(:puzzlespace,:puzzle_server_timeout))
          }
        )
      true ->
        {puzzleserver,timer} = state[puzzle]
        Process.cancel_timer(timer)
        Map.put(state,puzzle,
          {
            puzzleserver,
            Process.send_after(self(), {:timeout, puzzle}, Application.fetch_env!(:puzzlespace,:puzzle_server_timeout))
          }
        )
    end
    {res,_tim} = state[puzzle]
    {:reply,res,state}
  end

  @impl true
  def handle_info({:timeout,puzzle},state) do
    {puzzleserver,_timer} = state[puzzle]
    PLSI.stop(puzzleserver)
    state = Map.delete(state,puzzle)
    {:noreply,state}
  end

  def child_spec(arg) do
    %{ 
      id: __MODULE__,
      start: {__MODULE__, :start_link, [arg]}
    }
  end
end
