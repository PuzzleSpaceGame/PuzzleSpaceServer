defmodule PuzzlespaceWeb.PageController do
  use PuzzlespaceWeb, :controller
  alias Puzzlespace.User
  import Plug.Conn

  def index(conn, _params) do
    render(conn, "index.html")
  end
  
  def whoami(conn, _params) do
      name = case User.from_id(conn.assigns[:auth_uid]) do
        {:error, _} -> "Not logged in"
        {:ok,x} -> x.username
      end
    text(conn,"You are #{name}")
  end

  def login_user(conn, %{"username"=> username,"userpass" => _pass} = user_params) do
    case PuzzlespaceWeb.Authentication.login(user_params) do
      {:ok, _user, token} ->
        conn
        |> put_session(:user_token, token)
        |> put_flash(:info, "Welcome Back, #{username}")
        |> redirect(to: "/")
      {:error, _user} ->
        conn
        |> put_flash(:info, "Invalid Username or Password")
        |> redirect(to: "/login")
    end
  end

  def register_user(conn, %{"username"=> username,"userpass" => _pass} = user_params) do

    case PuzzlespaceWeb.Authentication.register(user_params) do
      {:ok, _user, token} ->
        conn
        |> put_session(:user_token, token)
        |> put_flash(:info, "Welcome to Puzzlespace, #{username}")
        |> redirect(to: "/")
      {:error, changeset} ->
        conn = conn
        |> put_flash(:info, "Account registration failed")
        Enum.reduce(changeset.errors,conn,
          fn {field,{condition,_}},c -> 
            put_flash(c,:info,"#{Atom.to_string(field)} #{condition}")
          end)
        |> redirect(to: "/login")
    end
  end

  def login_page(conn, _params) do
    render(conn, "login.html", csrf: Plug.CSRFProtection.get_csrf_token())
  end

  def logout(conn, _params) do
    case PuzzlespaceWeb.Authentication.logout(get_session(conn,:user_token)) do
      {:ok,_} -> 
        conn
        |> delete_session(:user_token)
        |> put_flash(:info, "See you, space cowboy")
        |> redirect(to: "/")
      {:error,_} ->
        conn
        |> put_flash(:info, "Error in logout")
        |> redirect(to: "/")
    end
  end

  def logout_many(conn, %{"signout_some" => "Signout Selected","tokens" = tokens} = params) do
    tokens
    |> Enum.map(fn token -> 
      PuzzlespaceWeb.Authentication.logout(token)
    end)
    case Enum.any?(tokens, fn token -> token == get_session(conn,:user_token) end) do
      true ->
        conn
        |> delete_session(:user_token)
        |> put_flash(:info, "See you, space cowboy")
        |> redirect(to: "/")
      false -> conn |> put_flash(:info, "Selected sessions ended") |> redirect(to: "/")
    end
  end

  def logout_many(conn, %{"signout_all" => _}) do
    Puzzlespace.AuthToken.list_tokens(conn.assigns[:auth_uid])
    |> Enum.map(fn token -> 
      PuzzlespaceWeb.Authentication.logout(token)
    end)
    conn
    |> delete_session(:user_token)
    |> put_flash(:info, "All sessions ended")
    |> put_flash(:info, "See you, space cowboy")
    |> redirect(to: "/")
  end

  def list_sessions(conn, _params) do
    tokens = Puzzlespace.AuthToken.list_tokens(conn.assigns[:auth_uid])
    render(conn, "listsessions.html", csrf: Plug.CSRFProtection.get_csrf_token(),tokens: tokens)
  end
  
  def list_saves(conn,_params) do
    {:ok, user} = User.from_id(conn.assigns[:auth_uid])
      saveslots = Puzzlespace.SaveSlot.list(user.user_entity)
    render(conn,"saves.html",saveslots: saveslots, csrf: Plug.CSRFProtection.get_csrf_token())
  end

  def new_save(conn,%{"slotname"=> name}) do
    {:ok, user} = User.from_id(conn.assigns[:auth_uid])
    {:ok, slot} = Puzzlespace.SaveSlot.new_saveslot(user.user_entity,name)
    load_save(conn, %{ "saveid" => slot.id})
  end

  def load_save(conn,%{"saveid"=> slotid,"delete"=> _}) do
    {:ok, _} = Puzzlespace.SaveSlot.delete(slotid)
    redirect(conn, to: "/puzzle/saves")
  end

  def load_save(conn,%{"saveid"=> slotid}=params) do
    Puzzlespace.SaveSlot.from_id(slotid)
    |> case do
      {:error,_} ->
        conn
        |> put_flash(:info, "Something's wrong with your savefile. Please contact the developer.")
        |> redirect(to: "/")
      {:ok,%Puzzlespace.SaveSlot{savedata: nil}} ->
        puzzles = Puzzlespace.Puzzles.list_puzzles()
        configs = 
          Enum.map(puzzles, &Puzzlespace.Puzzles.config/1)
        {:ok,config_json} = %{"configs" => Map.new(Enum.zip(puzzles,configs))}
                            |> Jason.encode(escape: :javascript_safe)
        config_json = config_json |> String.replace("\\\"","\\\\\"")
        render(conn,"puzzlepicker.html", csrf: Plug.CSRFProtection.get_csrf_token(), puzzles: puzzles, configs: config_json, slotid: slotid)
      {:ok,%Puzzlespace.SaveSlot{} = saveslot} ->
        {:ok,user} = Puzzlespace.User.from_id(conn.assigns[:auth_uid])
        {:ok, draw} = Puzzlespace.Puzzles.loadgame(user.user_entity,saveslot)
        play(conn,params,draw,slotid)
    end
  end

  def newgame(conn,%{"slotid" => slotid,"puzzle" => puzzle}=params) do
    {:ok,user} = Puzzlespace.User.from_id(conn.assigns[:auth_uid])
    {:ok,slot} = Puzzlespace.SaveSlot.from_id(slotid)
    {:ok,draw} = Puzzlespace.Puzzles.newgame(user.user_entity,slot,puzzle,params)
    play(conn,params,draw,slotid)
  end

  def play(conn,_params,draw,slotid) do
    {:ok,json} = Jason.encode(draw,pretty: true)
    {:ok,slot} = Puzzlespace.SaveSlot.from_id(slotid)
    {:ok,colors} = %{"colours" => Puzzlespace.Puzzles.list_colors(slot.puzzle)} |> Jason.encode()
    render(conn,"puzzleplayer.html", csrf: Plug.CSRFProtection.get_csrf_token(), draw: json, slotid: slot.id, colours: colors)
  end

  def update(conn,%{"user_input" => input,"slotid"=>slotid}) do
    {:ok,user} = Puzzlespace.User.from_id(conn.assigns[:auth_uid])
    {:ok,slot} = Puzzlespace.SaveSlot.from_id(slotid)
    {:ok,draw} = Puzzlespace.Puzzles.update(user.user_entity,slot,input)
    json(conn,draw)
  end
end
