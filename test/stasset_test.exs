
defmodule IndividualSTTests do
  defmacro __using__(_) do
    configured_puzzles = Application.fetch_env!(STAssetHandler,:asset_list)
                     |> Enum.map(fn [x|_] -> x end)
    Enum.map(configured_puzzles, fn tag -> 
      tag_str = Atom.to_string(tag)
      mod_name = String.to_atom(String.capitalize(tag_str) <> "Test" )
      quote do
        defmodule unquote(mod_name) do
          use ExUnit.Case
          import STAssetHelper
          alias Puzzlespace.STAssetHandler, as: STAH
      
          test unquote("list_colors: #{tag_str}") do
            colors = STAH.list_colors(unquote(tag))
            assert Enum.all?(colors,&valid_color?(&1))
          end
          
          test unquote("config: #{tag_str}") do
            cfg = STAH.config(unquote(tag))
            assert %{} = cfg
            assert Enum.all?(Map.keys(cfg),&String.valid?(&1))
            assert Enum.all?(Map.values(cfg),&Map.has_key?(&1,"default"))
            assert Enum.all?(Map.values(cfg),&Map.has_key?(&1,"type"))
            assert Enum.all?(Map.values(cfg),&Map.has_key?(&1,"name"))
          end

          test unquote("gameplay: #{tag_str}") do
            assert {draw,gamestate} = STAH.new_game(unquote(tag))
            assert valid_draw?(draw)
            assert valid_gamestate?(gamestate)
            move = [
              %{"pos_x"=>0,"pos_y"=>0,"buttons"=>["M1"],"mouse"=>"DOWN"},
              %{"pos_x"=>0,"pos_y"=>0,"buttons"=>["M1"],"mouse"=>"UP"}
            ]
            assert {draw,gamestate,_status} = STAH.update(unquote(tag),gamestate,move)
            assert valid_draw?(draw)
            assert valid_gamestate?(gamestate)
            assert {draw,gamestate,_status} = STAH.redraw(unquote(tag),gamestate)
            assert valid_draw?(draw)
            assert valid_gamestate?(gamestate)
            assert String.valid?(STAH.game_desc(unquote(tag),gamestate))
          end
 
        end
      end
    end)
  end
end


defmodule STAssetHelper do

  def valid_color?(%{"r"=>r,"g"=>g,"b"=>b}) when 
    is_float(r) and 
    is_float(g) and 
    is_float(b), do: true
  def valid_color?(_), do: false
  
  def valid_draw?(%{"cmds"=> cmds,"draw"=>true,"size"=>size}) do
    valid_cmds?(cmds) and valid_size?(size)
  end
  def valid_draw?(_), do: false

  def valid_size?(%{"x"=> x, "y"=> y}) when is_integer(x) and is_integer(y), do: true
  def valid_size?(_), do: false
  
  def valid_cmds?([_|_]), do: true
  def valid_cmds?([]), do: true
  def valid_cmds?(_), do: false

  def valid_gamestate?(gs) when is_binary(gs), do: true
  def valid_gamestate?(_), do: false

end

defmodule STTests do
  use IndividualSTTests
end
