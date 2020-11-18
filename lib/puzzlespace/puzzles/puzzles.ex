defmodule Puzzlespace.Puzzles do
  use Puzzlespace.Permissions
  alias Puzzlespace.SaveSlot
  alias Puzzlespace.Completion
  alias Puzzlespace.STAssetHandler, as: STImpl

  def newgame(entity,saveslot,tag,params \\ %{}) do
    if_permitted(entity, saveslot.owner, ["puzzle","create_saveslot"]) do
      {draw,gamestate} = STImpl.new_game(String.to_existing_atom(tag),params)
      SaveSlot.save(saveslot,tag,gamestate,0)
      draw
    end
  end

  def loadgame(entity,saveslot) do
    if_permitted(entity, saveslot.owner, ["puzzle","access_saveslot",saveslot]) do
      {puzzle,gamestate} = SaveSlot.load(saveslot)
      {draw,gamestate,status} = STImpl.redraw(String.to_existing_atom(saveslot.puzzle),gamestate)
      Completion.register_if_won(saveslot,status)
      SaveSlot.save(saveslot,puzzle,gamestate,status)
      case status do
        1 -> Map.put(draw,"won",true)
        -1 -> Map.put(draw,"lost",true)
        _ -> draw
      end
    end
  end

  def update(entity,saveslot,input) do
    if_permitted(entity, saveslot.owner, ["puzzle","access_saveslot"]) do
      {puzzle,gamestate} = SaveSlot.load(saveslot)
      {draw,gamestate,status} = STImpl.update(String.to_existing_atom(saveslot.puzzle),gamestate,input)
      Completion.register_if_won(saveslot,status)
      SaveSlot.save(saveslot,puzzle,gamestate,status)
      case status do
        1 -> Map.put(draw,"won",true)
        -1 -> Map.put(draw,"lost",true)
        _ -> draw
      end
    end
  end

  def config(puzzle) do
    STImpl.config(String.to_existing_atom(puzzle))
  end

  def list_puzzles() do
    STImpl.list_puzzles()
    |> Enum.map(&Atom.to_string/1)
  end

  def list_colors(puzzle) do
    STImpl.list_colors(String.to_existing_atom(puzzle))
  end

  def game_desc(saveslot) do
    {puzzle,gamestate} = SaveSlot.load(saveslot)
    desc = STImpl.game_desc(String.to_existing_atom(puzzle),gamestate)
    "#{puzzle}: #{desc}"
  end
end
