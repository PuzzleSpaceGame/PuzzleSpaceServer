defmodule Puzzlespace.Repo.Migrations.CreateAuthtokens do
  use Ecto.Migration

  def change do
    create table(:authtokens) do
      add :token, :string
      add :username, :string
      add :timestamp, :naive_datetime

      timestamps()
    end

    create unique_index(:authtokens, [:token])
  end
end
