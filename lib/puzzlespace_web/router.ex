defmodule PuzzlespaceWeb.Router do
  use PuzzlespaceWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PuzzlespaceWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/test", PuzzlespaceWeb do
    pipe_through :browser
    get "/", TestController, :index
    get "/msg/:messenger", TestController, :show
    get "/debug", TestController, :debug
    post "/login", TestController, :login_form
    get "/login", TestController, :login_page
  end

  # Other scopes may use custom stacks.
  # scope "/api", PuzzlespaceWeb do
  #   pipe_through :api
  # end
end
