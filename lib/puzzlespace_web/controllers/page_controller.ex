defmodule PuzzlespaceWeb.PageController do
  use PuzzlespaceWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
