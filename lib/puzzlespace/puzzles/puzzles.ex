defmodule Puzzlespace.Puzzles do
  use Puzzlespace.Permissions
  alias Puzzlespace.SaveSlot
  alias Puzzlespace.Completion

  def newgame(entity,saveslot,tag,params \\ %{}) do
    if_permitted(entity, saveslot.owner, ["puzzle","create_saveslot"]) do
      pcord = STPuzzleCoordinator
      {draw,gamestate} = pcord.new_game(String.to_existing_atom(tag),params)
      SaveSlot.save(saveslot,tag,gamestate,0)
      draw
    end
  end

  def loadgame(entity,saveslot) do
    if_permitted(entity, saveslot.owner, ["puzzle","access_saveslot",saveslot]) do
      pcord = STPuzzleCoordinator
      {puzzle,gamestate} = SaveSlot.load(saveslot)
      {draw,gamestate,status} = pcord.redraw(String.to_existing_atom(saveslot.puzzle),gamestate)
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
      pcord = STPuzzleCoordinator
      {puzzle,gamestate} = SaveSlot.load(saveslot)
      {draw,gamestate,status} = pcord.update(String.to_existing_atom(saveslot.puzzle),gamestate,input)
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
    pcord = STPuzzleCoordinator
    pcord.config(String.to_existing_atom(puzzle))
  end

  def list_puzzles() do
    pcord = STPuzzleCoordinator
    pcord.list_puzzles()
    |> Enum.map(&Atom.to_string/1)
  end

  def list_colors(puzzle) do
    pcord = STPuzzleCoordinator
    pcord.list_colors(String.to_existing_atom(puzzle))
  end

  def game_desc(saveslot) do
    pcord = STPuzzleCoordinator
    {puzzle,gamestate} = SaveSlot.load(saveslot)
    desc = pcord.game_desc(String.to_existing_atom(puzzle),gamestate)
    "#{puzzle}: #{desc}"
  end
end
