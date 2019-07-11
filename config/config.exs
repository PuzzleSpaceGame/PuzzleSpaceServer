# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :puzzlespace,
  ecto_repos: [Puzzlespace.Repo]

# Configures the endpoint
config :puzzlespace, PuzzlespaceWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "yJYIj8hwEFo80caREeL0rW59YoASCsn2jOpA1SzqzEYNSAOoB+2Uw5rtK7fID8yj",
  render_errors: [view: PuzzlespaceWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Puzzlespace.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
