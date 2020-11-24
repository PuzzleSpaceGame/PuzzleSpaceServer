import Config

alias Puzzlespace.STAssetHandler.STAsset, as: STA

config STAssetHandler,
  asset_list: [
    [
      :bridges, STA, "stbridges", 
      %{
        "Height" => 7,
        "Width" => 7,
        "Difficulty" => "Easy",
        "Allow loops" => false,
        "%age of island squares" => "15%",
        "Expansion factor (%age)" => "30%",
        "Max. bridges per direction" => "3",
      }
    ],
    [
      :unruly, STA, "stunruly",
      %{
        "Width" => 8,
        "Height" => 8,
        "Unique rows and columns" => false,
        "Difficulty" => "Normal",
      }
    ],
    [
      :loopy, STA, "stloopy",
      %{
        "Width" => 7,
        "Height" => 7,
        "Difficulty" => "Easy",
        "Grid type" => "Squares",
      }
    ],
    [
      :dominosa, STA, "stdominosa",
      %{
        "Maximum number on dominoes" => "6",
        "Difficulty" => "Basic",
      }
    ],
    [
      :filling, STA, "stfilling",
      %{
        "Width" => "13",
        "Height" => "9",
      }
    ],
    [
      :keen, STA, "stkeen",
      %{
        "Grid size" => "6",
        "Difficulty" => "Normal",
        "Multiplication only" => false,
      }
    ],
    [
      :mines, STA, "stmines",
      %{
        "Width" => "9",
        "Height" => "9",
        "Mines" => "10",
        "Ensure solubility" => true,
      },
    ],
    [
      :net, STA, "stnet",
      %{
        "Width" => "5",
        "Height" => "5",
        "Walls wrap around" => false,
        "Barrier probability" => 0,
        "Ensure unique solution" => true,
      }
    ],
    [
      :netslide, STA, "stnetslide",
      %{
        "Width" => "5",
        "Height" => "5",
        "Walls wrap around" => false,
        "Barrier probability" => 0,
        "Number of shuffling moves" => 0,
      }
    ],
    [
      :palisade, STA, "stpalisade",
      %{
        "Width" => "5",
        "Height" => "5",
        "Region size" => "5",
      },
    ],
    [
      :pattern, STA, "stpattern",
      %{
        "Width" => "15",
        "Height" => "15",
      },
    ],
    [
      :pearl, STA, "stpearl",
      %{
        "Width" => "8",
        "Height" => "8",
        "Difficulty" => "Tricky",
        "Allow unsoluble" => false,
      }, 
    ],
    [
      :range, STA, "strange",
      %{
        "Width" => "9",
        "Height" => "6",
      },
    ],
    [
      :rectangles, STA, "strectangles",
      %{
        "Width" => 7,
        "Height" => "7",
        "Expansion factor" => "0",
        "Ensure unique solution" => true,
      },
    ],
    [
      :singles, STA, "stsingles",
      %{
        "Width" => "5",
        "Height" => "5",
        "Difficulty" => "Easy",
      },
    ],
    [
      :slant, STA, "stslant",
      %{
        "Width" => "8",
        "Height" => "8",
        "Difficulty" => "Easy",
      },
    ],
    [
      :solo, STA, "stsolo",
      %{
        "Columns of sub-blocks" => "3",
        "Rows of sub-blocks" => "3",
        "\"X\" (require every number in each main diagonal)" => false,
        "Jigsaw (irregularly shaped sub-blocks)" => false,
        "Killer (digit sums)" => false,
        "Symmetry" => "2-way rotation",
        "Difficulty" => "Basic",
      },
    ],
    [
      :tents, STA, "sttents",
      %{
        "Width" => "8",
        "Height" => "8",
        "Difficulty" => "Easy",
      },
    ],
    [
      :towers, STA, "sttowers",
      %{
        "Grid size" => "5",
        "Difficulty" => "Easy",
      },
    ],
    [
      :tracks, STA, "sttracks",
      %{
        "Width" => "8",
        "Height" => "8",
        "Difficulty" => "Easy",
        "Disallow consecutive 1 clues" => false,
      },
    ],
    [
      :undead, STA, "stundead",
      %{
        "Width" => "8",
        "Height" => "8",
        "Difficulty" => "Easy",
      }
    ],
  ]
  



config Puzzlespace.Authentication,
  token_lifespan: 60*60*24

config Puzzlespace.Permissions,
  titles: %{
    "Founder" => [{"*"}]
  },
  structures: %{
    "Club" => %{
      "Officer" => [{"manage","*"},{"puzzle","*"},],
      "Member" => [{"puzzle","*"}]
    },
    "Union" => %{
      "Member" => [{"manage","*"},{"puzzle","*"}]
    }
  }
  
config :puzzlespace, Puzzlespace.Repo,
  migration_primary_key: [name: :id, type: :binary_id, autogenerate: true]

