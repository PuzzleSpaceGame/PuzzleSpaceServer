defmodule Puzzlespace.User do
  use Puzzlespace.Schema
  import Ecto.Changeset
  alias Puzzlespace.User
  alias Puzzlespace.Entity
  alias Puzzlespace.AuthToken

  schema "users" do
    field :username, :string, unique: true
    field :hashed_pass, :string
    field :userpass, :string, virtual: true

    belongs_to :user_entity, Entity, foreign_key: :entity_id
    has_many :auth_tokens, AuthToken
    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs,[:username,:userpass])
    |> validate_required([:username, :userpass])
    |> validate_length(:username,min: 1)
    |> unique_constraint(:username)
    |> hash_pass()
  end

  def hash_pass(changeset) do
    pass = fetch_field!(changeset,:userpass)
    changeset
    |> put_change(:hashed_pass,Pbkdf2.hash_pwd_salt(pass))
  end

  def from_name(nil), do: {:error, "is nil"}
  
  def from_name(name) do
    Puzzlespace.Repo.get_by(User,username: name)
    |> Puzzlespace.Repo.preload(:user_entity)
    |> case do
      nil -> {:error,"no user by name #{name} found"}
      x -> {:ok,x}
    end
  end 
  
  def from_id(nil), do: {:error,"is nil"}

  def from_id(uid) do
    Puzzlespace.Repo.get(User,uid)
    |> Puzzlespace.Repo.preload(:user_entity)
    |> case do
      nil -> {:error,"no user with uid #{uid} found"}
      x -> {:ok,x}
    end
  end
  
  def register(%{"username"=> _name,"userpass"=>_pass}=user_params) do
    User.changeset(%User{},user_params)
    |> put_change(:id,Ecto.UUID.bingenerate() |> Ecto.UUID.cast!())
    |> put_assoc(:user_entity,Entity.changeset(%Entity{},%{type: "user"}))
    |> Puzzlespace.Repo.insert()
  end

  def change_pass(%{"uid"=>uid,"newpass"=>newpass}) do
    User 
    |> Puzzlespace.Repo.get(uid)
    |> User.changeset(%{userpass: newpass})
    |> Puzzlespace.Repo.insert()
  end
end
