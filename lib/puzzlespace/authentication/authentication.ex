defmodule PuzzlespaceWeb.Authentication do
  alias Puzzlespace.User
  alias Puzzlespace.AuthToken
  alias Puzzlespace.SessionHandler

  def get_authenticated_user(token) do
    SessionHandler.get_authenticated_user(token,SessionHandler)
  end
  
  def login(%{"username"=>username,"userpass"=>userpass}) do
    case authenticate(username,userpass) do
      {:ok,user} -> 
        token = AuthToken.issue(user.id)
        {:ok,user.id,token}
      error -> error
    end
  end
  
  def logout(nil), do: {:error,"No active session"}
  
  def logout(token) do
    AuthToken.revoke(token)
  end

  def register(params) do
    case Puzzlespace.User.register(params) do
      {:ok,user} -> 
        token = AuthToken.issue(user.id)
        {:ok,user.id,token}
      {:error, changeset} ->
        {:error, changeset}
    end
  end
  
  defp authenticate(username,pass) do
    case User.from_name(username) do
      {:ok,user}-> 
        Pbkdf2.verify_pass(pass, user.hashed_pass)
        |> case do
          true -> {:ok,user}
          false -> {:error,"Invalid Password"}
        end
      x -> x
    end
  end
end


