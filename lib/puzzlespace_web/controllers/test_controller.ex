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
    IO.close(pid)
  end

  def login_page(conn, _params) do
    render(conn, "login.html", csrf: Plug.CSRFProtection.get_csrf_token())
  end

  def login_form(conn, %{"username"=> username,"userpass" => pass}) do
    text(conn, "#{username} ---> #{pass}")
  end

end
