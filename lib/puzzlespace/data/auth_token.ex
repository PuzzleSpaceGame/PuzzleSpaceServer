defmodule Puzzlespace.AuthToken do
  use Puzzlespace.Schema
  import Ecto.Changeset
  alias Puzzlespace.AuthToken
  alias Puzzlespace.User

  schema "authtokens" do
    field :token, :string 
    belongs_to :user, User, foreign_key: :user_id
    timestamps()
  end

  @doc false
  def changeset(auth_token, attrs) do
    auth_token
    |> cast(attrs, [:token, :user_id])
    |> validate_required([:token, :user_id])
    |> unique_constraint(:token)
  end

  def issue(uid) do
    AuthToken.changeset(%AuthToken{},
      %{token: :base64.encode(:crypto.strong_rand_bytes(20)), 
        user_id: uid
      }
    )
    |> Puzzlespace.Repo.insert()
    |> case do
      {:ok,token} -> token.token
      {:error,_} -> issue(uid) 
      end
  end

  def revoke(tokenval) do
    Puzzlespace.Repo.get_by(AuthToken,token: tokenval)
    |> Puzzlespace.Repo.delete()
  end

  def get_user(nil) do
    {:error, "Nil User"}
  end

  def get_user(token) do
    Puzzlespace.Repo.get_by(AuthToken,token: token)
    |> case do
      nil -> {:error,"Invalid Session Token"}
      x -> 
        case is_stale?(x) do
          true -> 
            Puzzlespace.Repo.delete(x)
            {:error,"Session Expired"}
          false -> {:ok,x.user_id}
        end
    end
  end

  def is_stale?(token) when is_bitstring(token) do
    Puzzlespace.Repo.get_by(AuthToken,token: token)
    |> AuthToken.is_stale?()
  end
  
  def is_stale?(%AuthToken{} = token) do
    NaiveDateTime.diff(token.updated_at,NaiveDateTime.local_now()) > Application.get_env(Puzzlespace.Authentication,:token_lifespan)
  end

  def list_tokens(%User{} = user) do
    user = user
    |> Puzzlespace.Repo.preload([:auth_tokens])
    user.auth_tokens
  end

  def list_tokens(uid) do
    {:ok,user} = User.from_id(uid)
    AuthToken.list_tokens(user)
  end

end
