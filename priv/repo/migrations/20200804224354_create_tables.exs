defmodule Puzzlespace.Repo.Migrations.CreateTables do
  use Ecto.Migration

  def change do
    create table(:entities) do
      add :type, :string
      timestamps()
    end
    
    create table(:users) do
      add :username, :string
      add :hashed_pass, :string
      add :entity_id, references(:entities)
      timestamps()
    end
    create unique_index(:users,[:username])
    create unique_index(:users,[:entity_id])
  
    create table(:authtokens) do
      add :token, :string
      add :userid, :binary_id
      timestamps()
    end
  
    create table(:saveslots) do
      add :name, :string
      add :puzzle, :string
      add :savedata, :text
      add :status, :integer
      add :owner_id, references(:entities)
      timestamps()
    end

    create table(:completions) do
      add :entity_id, references(:entities)
      add :name, :string
      add :desc, :text
      timestamps()
    end

  end
end
