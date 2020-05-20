defmodule Puzzlespace.Repo.Migrations.CreateSaveslots do
  use Ecto.Migration

  def change do
    create table(:saveslots) do
      add :puzzle, :string
      add :savedata, :string

      timestamps()
    end
  end
end
