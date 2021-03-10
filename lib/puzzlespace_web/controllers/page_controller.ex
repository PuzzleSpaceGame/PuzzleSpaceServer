defmodule PuzzlespaceWeb.PageController do
  use PuzzlespaceWeb, :controller
  alias Puzzlespace.User
  alias Puzzlespace.Organization, as: Org
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

  def logout_many(conn, %{"signout_some" => "Signout Selected","tokens" => tokens}) do
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
    render(conn,"saves.html",user: user, csrf: Plug.CSRFProtection.get_csrf_token())
  end

  def new_save(conn,%{"slotname"=> name,"entity_id"=> primary_id}) do
    {:ok, user} = User.from_id(conn.assigns[:auth_uid])
    primary = Puzzlespace.Repo.get(Puzzlespace.Entity,primary_id)
    if Puzzlespace.Permissions.granted?(user.user_entity,primary,["puzzle","create_saveslot"]) do
      {:ok, slot} = Puzzlespace.SaveSlot.new_saveslot(primary,name)
      load_save(conn, %{ "saveid" => slot.id})
    else
      conn
      |> put_flash(:info, "Permission Denied")
      |> index(%{})
    end
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
    render(conn,"puzzleplayer.html", csrf: Plug.CSRFProtection.get_csrf_token(), draw: json, slot: slot, colours: colors)
  end

  def update(conn,%{"user_input" => input,"slotid"=>slotid}) do
    {:ok,user} = Puzzlespace.User.from_id(conn.assigns[:auth_uid])
    {:ok,slot} = Puzzlespace.SaveSlot.from_id(slotid)
    {:ok,draw} = Puzzlespace.Puzzles.update(user.user_entity,slot,input)
    json(conn,draw)
  end

  def my_profile(conn,_) do
    profile(conn,%{"user_id" => conn.assigns[:auth_uid]})
  end

  def profile(conn,%{"user_id" => uid}) do
    {:ok, user} = User.from_id(conn.assigns[:auth_uid])
    {:ok, profile_owner} = User.from_id(uid)
    render(conn,"profile.html",
      csrf: Plug.CSRFProtection.get_csrf_token(),
      user: user,
      profile_user: profile_owner
    )
  end

  def mail_api(conn,%{"Invite" => "Invite", "username" => usrname, "org_id" => oid, "title" => title}) do
    {:ok, inviter} = User.from_id(conn.assigns[:auth_uid])
    with {:ok,invitee} <- User.from_name(usrname),
         {:ok,org} <- Org.from_id(oid),
         {:ok, _} <- Puzzlespace.OrganizationManagement.invite_player(inviter.user_entity,org.org_entity,invitee.user_entity, title) do
      text(conn,"Invite Sent")
    else
      {:error,reason} -> text(conn,"Invitation failed: #{reason}")
    end
  end

  def mail_api(conn,%{"notif_id" => notif_id, "action" => action}) do
    case Puzzlespace.Notification.handle_action(notif_id,action) do
      :ok ->
        text(conn,"Notification Handled")
      {:ok, _} ->
        text(conn,"Notification Handled")
      {:error,reason} ->
        text(conn,"Error: #{reason}")
    end
  end

  def new_team(conn,_) do
    render(conn,"newteam.html",
      csrf: Plug.CSRFProtection.get_csrf_token(),
      structures: Application.get_env(Puzzlespace.Permissions,:structures)
    )
  end

  def create_team(conn, %{"name"=> name, "structure"=> structure}) do
    {:ok, user} = User.from_id(conn.assigns[:auth_uid])
    {:ok, org} = Puzzlespace.OrganizationManagement.found_org(user.user_entity,name)
    {:ok, user} = User.from_id(conn.assigns[:auth_uid])
    {:ok,_} = Puzzlespace.OrganizationManagement.adopt_structure(user.user_entity,org.org_entity,structure)
    org_profile(conn,%{"org_id" => org.id})
  end

  def org_profile(conn,%{"org_id" => oid}) do
    {:ok,org} = Org.from_id(oid)
    {:ok, user} = User.from_id(conn.assigns[:auth_uid])
    render(conn,"orgprofile.html",
      csrf: Plug.CSRFProtection.get_csrf_token(),
      org: org,
      user: user
    )
  end
end
