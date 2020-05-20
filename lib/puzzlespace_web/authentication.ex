defmodule PuzzlespaceWeb.Authentication do
  alias Puzzlespace.User
  alias Puzzlespace.AuthToken
  import Plug.Conn
  def login(params, repo) do
    user = repo.get_by(User, username: params["username"])
    case authenticate(user,params["userpass"]) do
      true -> 
        token = :base64.encode(:crypto.strong_rand_bytes(20))
        AuthToken.changeset(%AuthToken{},
          %{token: token, 
            username: params["username"], 
            timestamp: NaiveDateTime.utc_now()
          }
        )
        |> repo.insert() 
        {:ok,user,token}

      _    -> {:error, user}
    end
  end
  
  def logout(conn,repo) do
    token = get_session(conn,"user_token")
    repo.get_by(AuthToken,token: token)
    |> repo.delete()
    conn = delete_session(conn,"user_token")
    {:ok,conn}
  end
  
  def init(options) do
    options
  end

  def call(conn, _opts) do
    get_authenticated_user(conn,Puzzlespace.Repo)
  end

  def get_authenticated_user(conn,repo) do
    conn 
    |> put_private(:auth_user,get_user(conn,repo))
  end

  def get_user(conn,repo) do
    token = conn.private.plug_session["user_token"]
    case token do
      nil -> nil
      _ -> repo.get_by(AuthToken, token: token).username
    end  
  end

  defp authenticate(user,pass) do
    case user do
      nil -> false
      _   -> Bcrypt.verify_pass(pass, user.hashed_pass)
    end
  end
end
