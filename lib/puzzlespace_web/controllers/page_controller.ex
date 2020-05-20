defmodule PuzzlespaceWeb.PageController do
  use PuzzlespaceWeb, :controller
  alias Puzzlespace.User

  def index(conn, _params) do
    render(conn, "index.html")
  end
  
  def whoami(conn, _params) do
    name = PuzzlespaceWeb.Authentication.get_user(conn,Puzzlespace.Repo)
    text(conn,"You are #{name}")
  end

  def login_user(conn, %{"username"=> username,"userpass" => _pass} = user_params) do
    case PuzzlespaceWeb.Authentication.login(user_params,Puzzlespace.Repo) do
      {:ok, user, token} ->
        conn
        |> put_session(:user_token, token)
        |> put_flash(:info, "Welcome Back, #{user}")
        |> redirect(to: "/")
      {:error, _user} ->
        conn
        |> put_flash(:info, "Invalid Username or Password")
        |> redirect(to: "/login")
    end
  end

  def register_user(conn, %{"username"=> username,"userpass" => _pass} = user_params) do
    changeset = User.changeset(%User{}, user_params)

    case PuzzlespaceWeb.Registration.create(changeset, Puzzlespace.Repo) do
      {:ok, _changeset} ->
        conn
        |> put_flash(:info, "Welcome to Puzzlespace, #{username}")
        |> redirect(to: "/")
      {:error, _changeset} ->
        conn
        |> put_flash(:info, "Account registration failed")
        |> redirect(to: "/login")
    end
  end

  def login_page(conn, _params) do
    render(conn, "login.html", csrf: Plug.CSRFProtection.get_csrf_token())
  end

  def logout(conn, _params) do
    case PuzzlespaceWeb.Authentication.logout(conn,Puzzlespace.Repo) do
      {:ok,conn} -> 
        conn
        |> put_flash(:info, "See you, space cowboy")
        |> redirect(to: "/")
      {:error,conn} ->
        conn
        |> put_flash(:info, "Error in logout")
        |> redirect(to: "/")
    end
  end
end
