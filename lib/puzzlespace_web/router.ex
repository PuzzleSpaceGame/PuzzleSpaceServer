defmodule PuzzlespaceWeb.Router do
  use PuzzlespaceWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug PuzzlespaceWeb.SessionPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug PuzzlespaceWeb.SessionPlug
  end

  scope "/", PuzzlespaceWeb do
    pipe_through :browser
    get "/whoami", PageController, :whoami
    get "/login", PageController, :login_page
    post "/login/submit_login", PageController, :login_user
    post "/login/submit_register", PageController, :register_user
    get "/logout/list", PageController, :list_sessions
    post "/logout", PageController, :logout_many
    get "/logout", PageController, :logout
    get "/", PageController, :index
  end

  scope "/test", PuzzlespaceWeb do
    pipe_through :browser
    get "/msg/:messenger", TestController, :show
    get "/debug", TestController, :debug
    get "/", TestController, :index
  end

  scope "/social", PuzzlespaceWeb do
    pipe_through :browser
    get "/profile", PageController, :my_profile
    get "/profile/:user_id", PageController, :profile
    get "/team/new", PageController, :new_team
    post "/team/new", PageController, :create_team
    get "/team/:org_id", PageController, :org_profile
  end

  scope "/mailbox", PuzzlespaceWeb do
    pipe_through :api
    post "/api", PageController, :mail_api
  end

  scope "/puzzle", PuzzlespaceWeb do
    pipe_through :browser
    get "/saves", PageController, :list_saves
    post "/new_save", PageController, :new_save
    post "/load", PageController, :load_save
    post "/newgame", PageController, :newgame
  end

  scope "/puzzleapi", PuzzlespaceWeb do
    pipe_through :api
    post "/update", PageController, :update
  end
    # Other scopes may use custom stacks.
  # scope "/api", PuzzlespaceWeb do
  #   pipe_through :api
  # end
end
