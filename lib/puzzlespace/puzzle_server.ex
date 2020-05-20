defmodule Puzzlespace.PuzzleServer do
  alias Puzzlespace.PuzzleLogicServerInterface, as: PLSI
  alias Puzzlespace.PuzzleServerDirectory, as: SD
  alias Puzzlespace.SaveSlot

  import Plug.Conn
  require Logger

  def init(_opts) do
    %{sd: Puzzlespace.PuzzleServerDirectory,
      repo: Puzzlespace.Repo
    }
  end
  
  def call(%{private: %{auth_user: user}, params: %{newgame: true, puzzle: puzzle} } = conn, %{sd: sd, repo: repo} = _opts) do
    conn  
    |> put_private(:drawlist,new_game(sd,repo,puzzle, saveslotId))
  end
  
  def call(conn,opts) do
    conn
  end
  
  def new_game(sd,repo,puzzle,saveslotId) do
    pzs = SD.get_server(sd,puzzle)
    {drawlist,savedata} = PLSI.puzzle_lifespan(pzs)
    case repo.get(SaveSlot, saveslotId) do
      nil -> %SaveSlot{id: saveslotId}
      other -> other
    end
    |> SaveSlot.changeset(%{puzzle: puzzle,savedata: savedata})
    |> repo.insert_or_update() 
    Logger.info("New #{puzzle} game in slot #{saveslotId}") 
    drawlist
  end
  
  def load_game(sd,repo,saveslotId) do 
    saveslot = repo.get(SaveSlot, saveslotId)
    pzs = SD.get_server(sd,saveslot.puzzle)
    {drawlist,savedata} = PLSI.puzzle_lifespan(pzs,saveslot.savedata)
    SaveSlot.changeset(saveslot,%{savedata: savedata})
    |> repo.insert_or_update()
    Logger.info("Load #{saveslot.puzzle} game in slot #{saveslotId}")
    drawlist
  end

  def available_slot(user,_puzzle) do
    1
  end
end
