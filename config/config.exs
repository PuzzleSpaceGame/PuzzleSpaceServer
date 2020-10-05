# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :puzzlespace,
  ecto_repos: [Puzzlespace.Repo],
  puzzle_server_timeout: 1000*60*10
# Configures the endpoint
config :puzzlespace, PuzzlespaceWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "yJYIj8hwEFo80caREeL0rW59YoASCsn2jOpA1SzqzEYNSAOoB+2Uw5rtK7fID8yj",
  render_errors: [view: PuzzlespaceWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: Puzzlespace.PubSub
# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.


import_config "#{Mix.env()}.exs"
import_config "game.exs"
