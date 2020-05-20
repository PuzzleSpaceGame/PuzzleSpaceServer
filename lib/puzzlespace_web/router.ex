defmodule PuzzlespaceWeb.Router do
  use PuzzlespaceWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug PuzzlespaceWeb.Authentication
  end

  pipeline :puzzle do
    plug Puzzlespace.PuzzleServer
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PuzzlespaceWeb do
    pipe_through :browser
    get "/whoami", PageController, :whoami
    get "/login", PageController, :login_page
    post "/login/submit_login", PageController, :login_user
    post "/login/submit_register", PageController, :register_user
    get "/logout", PageController, :logout
    get "/", PageController, :index
  end

  scope "/test", PuzzlespaceWeb do
    pipe_through :browser
    get "/msg/:messenger", TestController, :show
    get "/debug", TestController, :debug
    post "/login", TestController, :login_form
    get "/login", TestController, :login_page 
    get "/", TestController, :index
  end

  scope "/puzzle", PuzzlespaceWeb do
    pipe_through :browser
    pipe_through :puzzle
    get "/", PuzzleController, :choose_puzzle 
  end
    # Other scopes may use custom stacks.
  # scope "/api", PuzzlespaceWeb do
  #   pipe_through :api
  # end
end
