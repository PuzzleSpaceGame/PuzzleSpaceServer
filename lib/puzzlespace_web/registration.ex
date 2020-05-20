defmodule PuzzlespaceWeb.Registration do
  import Ecto.Changeset, only: [put_change: 3]

  def create(changeset, repo) do
    changeset
    |> IO.inspect
    |> put_change(:hashed_pass,Bcrypt.hash_pwd_salt(changeset.changes.userpass))
    |> repo.insert()
  end
end
