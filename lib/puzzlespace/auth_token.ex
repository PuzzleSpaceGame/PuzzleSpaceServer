defmodule Puzzlespace.AuthToken do
  use Ecto.Schema
  import Ecto.Changeset
  
  schema "authtokens" do
    field :timestamp, :naive_datetime
    field :token, :string, primary_key: true 
    field :username, :string
    
    timestamps()
  end

  @doc false
  def changeset(auth_token, attrs) do
    auth_token
    |> cast(attrs, [:token, :username, :timestamp])
    |> validate_required([:token, :username, :timestamp])
    |> unique_constraint(:token)
  end
end
