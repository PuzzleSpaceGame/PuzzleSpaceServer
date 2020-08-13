defmodule Puzzlespace.STPuzzChannel do
  use Phoenix.Channel
  
  def join("stpuzz:" <> gameid, socket) do
    {:ok, socket}
  end
end
