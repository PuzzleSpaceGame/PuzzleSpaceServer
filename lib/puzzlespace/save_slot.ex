defmodule Puzzlespace.SaveSlot do
  use Ecto.Schema
  import Ecto.Changeset

  schema "saveslots" do
    field :puzzle, :string
    field :savedata, :string

    timestamps()
  end

  @doc false
  def changeset(save_slot, attrs) do
    save_slot
    |> cast(attrs, [:puzzle, :savedata])
    |> validate_required([:puzzle, :savedata])
  end
end
