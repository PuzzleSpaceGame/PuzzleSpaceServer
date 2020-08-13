defmodule Puzzlespace.SaveSlot do
  use Puzzlespace.Schema
  import Ecto.Changeset
  alias Puzzlespace.Entity
  alias Puzzlespace.SaveSlot

  schema "saveslots" do
    field :name, :string
    field :puzzle, :string
    field :savedata, :string
    field :status, :integer

    belongs_to :owner, Entity 

    timestamps()
  end

  @doc false
  def changeset(%SaveSlot{} = save_slot \\ %SaveSlot{}, attrs \\ %{}) do
    save_slot
    |> cast(attrs, [:name, :puzzle, :savedata,:status])
  end

  def new_saveslot(%Entity{} = entity,name) do
    SaveSlot.changeset(%SaveSlot{},%{name: name})
    |> put_assoc(:owner,entity)
    |> Puzzlespace.Repo.insert()
  end

  def from_id(saveid) do
    Puzzlespace.Repo.get(SaveSlot,saveid)
    |> case do
      nil -> {:error,"No saveslot found"}
      x -> {:ok, Puzzlespace.Repo.preload(x,:owner)}
    end
  end

  def save(%SaveSlot{} = saveslot,puzzle,savedata,status) when is_atom(puzzle) do
    SaveSlot.save(saveslot,Atom.to_string(puzzle),savedata,status)
  end

  def save(%SaveSlot{} = saveslot,puzzle,savedata,status) do
    SaveSlot.changeset(saveslot,%{puzzle: puzzle,savedata: savedata,status: status})
    |> Puzzlespace.Repo.update()
  end

  def save(slotid,puzzle,savedata) do 
    Puzzlespace.Repo.get(SaveSlot,slotid)
    |> SaveSlot.save(puzzle,savedata)
  end

  def load(%SaveSlot{} = saveslot) do
    {saveslot.puzzle,saveslot.savedata}
  end

  def load(slotid) do 
    Puzzlespace.Repo.get(SaveSlot,slotid)
    |> SaveSlot.load()
  end

  def delete(%SaveSlot{} = saveslot) do
    Puzzlespace.Repo.delete(saveslot)
  end

  def delete(slotid) do 
    Puzzlespace.Repo.get(SaveSlot,slotid)
    |> SaveSlot.delete()
  end
  
  def list(%Entity{} = entity) do
    entity = Puzzlespace.Repo.preload(entity,:save_slots)
    entity.save_slots
  end

  def to_string(%SaveSlot{puzzle: nil, name: name, inserted_at: date}) do
    "Unassigned: #{name} created #{NaiveDateTime.to_string(date)}"
  end

  def to_string(%SaveSlot{name: name, puzzle: puzzle, inserted_at: date}) do
    IO.inspect puzzle
    "#{puzzle}: #{name}, created #{NaiveDateTime.to_string(date)}"
  end
end
