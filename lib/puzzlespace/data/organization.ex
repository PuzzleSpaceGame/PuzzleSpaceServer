defmodule Puzzlespace.Organization do
  use Puzzlespace.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias Puzzlespace.Organization, as: Org
  alias Puzzlespace.Relationship
  alias Puzzlespace.Entity
  alias Ecto.Multi

  schema "organizations" do
    field :name, :string, unique: true
    belongs_to :org_entity, Entity, foreign_key: :entity_id
    timestamps()
  end

  def changeset(%Org{}=org,attrs) do
    org
    |> cast(attrs,[:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
    |> validate_length(:name, min: 1)
  end

  def from_id(nil), do: {:error,"is nil"}
  
  def from_id(oid) do
    Puzzlespace.Repo.get(Org,oid)
    |> Puzzlespace.Repo.preload(:org_entity)
    |> Org.load_perm_map()
    |> case do
      nil -> {:error, "no organization with #{oid} found"}
      x -> {:ok,x}
    end
  end

  def from_entity_id(nil), do: {:error, "is nil"}
  def from_entity_id(id) do
    (from u in Puzzlespace.Organization,
      where: u.entity_id == ^id,
      select: u
    )
    |> Puzzlespace.Repo.one()
    |> case do
      nil -> {:error, "no org with eid #{id} found"}
      x -> {:ok, x}
    end
  end

  def from_name(nil), do: {:error, "is nil"}
  
  def from_name(name) do
    Puzzlespace.Repo.get_by(Org,name: name)
    |> Puzzlespace.Repo.preload(:org_entity)
    |> Org.load_perm_map()
    |> case do
      nil -> {:error,"no organization by name #{name} found"}
      x -> {:ok,x}
    end
  end

  def load_perm_map(%Org{} = org) do
    %{org | org_entity: Relationship.load_permissions(org.org_entity)}
  end
  def load_perm_map(_), do: nil
 
  def found_org(founder_id,name) do
    Multi.new()
    |> Multi.insert(:create_org,Org.create_org(name))
    |> Multi.merge(fn %{create_org: org} -> Org.add_founder(org.entity_id,founder_id) end)
    |> Puzzlespace.Repo.transaction()
  end
  
  def create_org(name) do
    Org.changeset(%Org{},%{name: name})
    |> put_assoc(:org_entity,Entity.changeset(%Entity{},%{type: "org"}))
  end

  def add_founder(org_ent_id,founder_eid) do
    IO.inspect("org_ent_id: #{org_ent_id}, founder_eid: #{founder_eid}")
    Multi.new()
    |> Multi.insert(
      :create_title,Puzzlespace.Permissions.Prototype.use_preset_title(org_ent_id,"Founder",:changeset)
    )
    |> Multi.insert(:assign_title,fn _ -> Relationship.assign_title(org_ent_id,"Founder",founder_eid,:changeset) end)
  end


  defimpl Puzzlespace.EntityBacked do
    def name(%Org{} = org), do: org.name
    def url(%Org{} = org), do: "/social/team/#{org.id}"
  end
end
