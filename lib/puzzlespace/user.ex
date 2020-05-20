defmodule Puzzlespace.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Puzzlespace.User

  schema "users" do
    field :hashed_pass, :string
    field :username, :string
    field :userpass, :string, virtual: true

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs,[:username,:userpass])
    |> validate_required([:username, :userpass])
    |> unique_constraint(:username)
  end
end
