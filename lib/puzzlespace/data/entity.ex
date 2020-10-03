defmodule Puzzlespace.Entity do
  use Puzzlespace.Schema
  import Ecto.Changeset
  alias Puzzlespace.SaveSlot
  alias Puzzlespace.Entity
  alias Puzzlespace.Completion
  alias Puzzlespace.Relationship
  alias Puzzlespace.Notification

  schema "entities" do
    field :type, :string
    field :perm_map, :any, virtual: true

    has_many :save_slots, SaveSlot, foreign_key: :owner_id
    has_many :completions, Completion, foreign_key: :entity_id
    has_many :granting_relationships, Relationship, foreign_key: :primary_id
    has_many :recieving_relationships, Relationship, foreign_key: :reciever_id
    has_many :inbox, Notification, foreign_key: :reciever_id
    has_many :outbox, Notification, foreign_key: :sender_id
    
    timestamps()
  end

  def changeset(%Entity{} = entity,attrs) do
    entity
    |> cast(attrs,[:type])
    |> validate_required([:type])
  end

  def type(%Entity{} = entity) do
    case entity.type do
      "org" -> Puzzlespace.Organization
      "user" -> Puzzlespace.User
      _ -> nil
    end
  end

  def represents(%Entity{} = entity) do
    case type(entity) do
      nil -> {:error, "entity lacks representative type"}
      x -> x.from_entity_id(entity.id)
    end
  end

  def can_grant(%Entity{} = entity) do
    entity = entity
    |> Puzzlespace.Repo.preload(:granting_relationships)
    entity.granting_relationships
    |> Enum.filter( fn rel -> rel.primary_id == rel.reciever_id end)
    |> Enum.map(fn rel -> rel.title end)
  end
  
end
