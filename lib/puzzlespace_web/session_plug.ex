defmodule PuzzlespaceWeb.SessionPlug do
  import Plug.Conn

  def init(opts) do
    Puzzlespace.SessionHandler
  end

  def call(conn,cache) do
    uid = get_session(conn,:user_token)
          |> Puzzlespace.SessionHandler.get_authenticated_user(cache)
    conn
    |>assign(:auth_uid,uid)
  end
end
