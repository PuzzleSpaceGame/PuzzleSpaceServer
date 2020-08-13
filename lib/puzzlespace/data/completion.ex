defmodule Puzzlespace.Completion do
  use Puzzlespace.Schema
  import Ecto.Changeset
  alias Puzzlespace.SaveSlot
  alias Puzzlespace.Completion
  alias Puzzlespace.Entity

  schema "completions" do
    belongs_to :entity, Entity
    field :name, :string
    field :desc, :string
    timestamps()
  end

  def changeset(%Completion{} = completion,attrs) do
    completion
    |> cast(attrs,[:name,:desc,:entity_id])
    |> validate_required([:entity_id,:desc])
  end

  def register(%SaveSlot{} = saveslot) do
    desc = Puzzlespace.Puzzles.game_desc(saveslot)
    Completion.changeset(%Completion{},
      %{entity_id: saveslot.owner.id,name: saveslot.name,desc: desc}
    )
    |> Puzzlespace.Repo.insert()
  end

  def register_if_won(%SaveSlot{status: 0} = saveslot,+1) do
    {:ok,_} = Completion.register(saveslot)
    :ok
  end

  def register_if_won(%SaveSlot{},_), do: :nochange
end
