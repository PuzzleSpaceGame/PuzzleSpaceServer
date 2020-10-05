import Config

config STPuzzleCoordinator, 
  connopts: [ 
    host: "192.168.1.142",
    port: 5672,
    username: "psserver",
    password: "fizzbuzz",
  ],
  queues: [
    bridges: "stbridges",
    unruly: "stunruly",
    loopy: "stloopy",
    dominosa: "stdominosa",
    filling: "stfilling",
    keen: "stkeen",
    mines: "stmines",
    net: "stnet",
    netslide: "stnetslide",
    palisade: "stpalisade",
    pattern: "stpattern",
    pearl: "stpearl",
    range: "strange",
    rectangles: "strectangles",
    singles: "stsingles",
    slant: "stslant",
    solo: "stsolo",
    tents: "sttents",
    towers: "sttowers",
    tracks: "sttracks",
    undead: "stundead",
  ],
  default_config: %{
    bridges: %{
      "Height" => 7,
      "Width" => 7,
      "Difficulty" => "Easy",
      "Allow loops" => false,
      "%age of island squares" => "15%",
      "Expansion factor (%age)" => "30%",
      "Max. bridges per direction" => "3",
    },
    unruly: %{
      "Width" => 8,
      "Height" => 8,
      "Unique rows and columns" => false,
      "Difficulty" => "Normal",
    },
    loopy: %{
      "Width" => 7,
      "Height" => 7,
      "Difficulty" => "Easy",
      "Grid type" => "Squares",
    },
    dominosa: %{
      "Maximum number on dominoes" => "6",
      "Difficulty" => "Basic",
    },
    filling: %{
      "Width" => "13",
      "Height" => "9",
    },
    keen: %{
      "Grid size" => "6",
      "Difficulty" => "Normal",
      "Multiplication only" => false,
    },
    mines: %{
      "Width" => "9",
      "Height" => "9",
      "Mines" => "10",
      "Ensure solubility" => true,
    },
    net: %{
      "Width" => "5",
      "Height" => "5",
      "Walls wrap around" => false,
      "Barrier probability" => 0,
      "Ensure unique solution" => true,
    },
    netslide: %{
      "Width" => "5",
      "Height" => "5",
      "Walls wrap around" => false,
      "Barrier probability" => 0,
      "Number of shuffling moves" => 0,
    },
    palisade: %{
      "Width" => "5",
      "Height" => "5",
      "Region size" => "5",
    },
    pattern: %{
      "Width" => "15",
      "Height" => "15",
    },
    pearl: %{
      "Width" => "8",
      "Height" => "8",
      "Difficulty" => "Tricky",
      "Allow unsoluble" => false,
    },
    range: %{
      "Width" => "9",
      "Height" => "6",
    },
    rectangles: %{
      "Width" => 7,
      "Height" => "7",
      "Expansion factor" => "0",
      "Ensure unique solution" => true,
    },
    singles: %{
      "Width" => "5",
      "Height" => "5",
      "Difficulty" => "Easy",
    },
    slant: %{
      "Width" => "8",
      "Height" => "8",
      "Difficulty" => "Easy",
    },
    solo: %{
      "Columns of sub-blocks" => "3",
      "Rows of sub-blocks" => "3",
      "\"X\" (require every number in each main diagonal)" => false,
      "Jigsaw (irregularly shaped sub-blocks)" => false,
      "Killer (digit sums)" => false,
      "Symmetry" => "2-way rotation",
      "Difficulty" => "Basic",
    },
    tents: %{
      "Width" => "8",
      "Height" => "8",
      "Difficulty" => "Easy",
    },
    towers: %{
      "Grid size" => "5",
      "Difficulty" => "Easy",
    },
    tracks: %{
      "Width" => "8",
      "Height" => "8",
      "Difficulty" => "Easy",
      "Disallow consecutive 1 clues" => false,
    },
    undead: %{
      "Width" => "8",
      "Height" => "8",
      "Difficulty" => "Easy",
    }
  }

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

