defmodule Puzzlespace.Repo do
  use Ecto.Repo,
    otp_app: :puzzlespace,
    adapter: Ecto.Adapters.Postgres
end
