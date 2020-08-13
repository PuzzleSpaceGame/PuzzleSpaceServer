defmodule PuzzlespaceWeb.TestController do
  use PuzzlespaceWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def show(conn,%{"messenger" => messenger}) do
    render(conn, "show.html", messenger: messenger)
  end

  def debug(conn, _params) do
    {:ok,pid} = StringIO.open("",[:write])
    IO.inspect(pid,conn,[])
    text(conn, StringIO.flush(pid))
  end

end
