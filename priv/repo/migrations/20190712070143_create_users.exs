defmodule Puzzlespace.Repo.Migrations.CreateUsers do
  use Ecto.Migration
  import Ecto.Changeset
  alias Puzzlespace.User

  def change do
    create table(:users) do
      add :username, :string
      add :hashed_pass, :string

      timestamps()
    end

    create unique_index(:users, [:username])
  end

end
