defmodule PuzzlespaceWeb.SessionPlug do
  import Plug.Conn

  def init(_opts) do
    Puzzlespace.SessionHandler
  end

  def call(conn,cache) do
    token = get_session(conn,:user_token)
    uid = Puzzlespace.SessionHandler.get_authenticated_user(token,cache)
    conn
    |>assign(:auth_uid,uid)
    |>assign(:auth_token,token)
  end
end
