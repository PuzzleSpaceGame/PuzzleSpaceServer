defmodule Puzzlespace.Entity do
  use Puzzlespace.Schema
  import Ecto.Changeset
  alias Puzzlespace.SaveSlot
  alias Puzzlespace.Entity
  alias Puzzlespace.Completion

  schema "entities" do
    field :type, :string

    has_many :save_slots, SaveSlot, foreign_key: :owner_id
    has_many :completions, Completion, foreign_key: :entity_id
    timestamps()
  end

  def changeset(%Entity{} = entity,attrs) do
    entity
    |> cast(attrs,[:type])
    |> validate_required([:type])
  end
end
