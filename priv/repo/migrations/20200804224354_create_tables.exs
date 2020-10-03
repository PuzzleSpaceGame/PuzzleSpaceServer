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
      add :user_id, references(:users)
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

    create table(:relationships) do
      add :primary_id, references(:entities)
      add :title, :string
      add :reciever_id, references(:entities)
      add :permissions, {:array, {:array, :string}}
      timestamps()
    end
    create unique_index(:relationships,[:primary_id,:reciever_id,:title], name: :"duplicate title assignment")

    create table(:organizations) do
      add :name, :string
      add :entity_id, references(:entities)
      timestamps()
    end
    create unique_index(:organizations,[:name])

    create table(:notifications) do
      add :sender_id, references(:entities)
      add :reciever_id, references(:entities)
      add :payload, {:map, :string}
      timestamps()
    end
  end
end
