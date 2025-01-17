defmodule PuzzlespaceWeb.PuzzleSocket do
  use Phoenix.Socket
  alias PuzzlespaceWeb.Authentication
  alias Puzzlespace.User
  ## Channels
  channel "stpuzz:*", PuzzlespaceWeb.STPuzzChannel

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(%{"auth_token"=>authtoken}, socket, _connect_info) do
    case Authentication.get_authenticated_user(authtoken) do
      nil -> :error
      uid -> 
        {:ok,user} = User.from_id(uid)
        socket = 
          socket
          |> assign(:user,user)
        {:ok,socket}
    end
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     PuzzlespaceWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(socket), do: "user_socket:#{socket.assigns.user.id}"
end
