defmodule Puzzlespace.Permissions.Prototype do
  alias Ecto.Multi
  import Ecto.Changeset
  
  alias Puzzlespace.Entity
  alias Puzzlespace.Organization, as: Org
  alias Puzzlespace.Permissions.Prototype, as: Prototype

  def use_preset_title(primary_id,title,action \\ :insert) do
    case get_prototype_id("Title") do
      {:ok, proto_id} -> Puzzlespace.Relationship.inherit_title(proto_id,primary_id,title,title,action)
      x -> x
    end
  end

  def use_preset_structure(primary_id,preset,action \\ :insert) do
    case get_prototype_id(preset) do
      {:ok, proto_id} -> Puzzlespace.Relationship.inherit_structure(proto_id,primary_id,action)
      x -> x
    end
  end
  
  def get_prototype_id(prototype) do
    case Org.from_name(prototype <> "Prototype") do
        {:ok,org} -> {:ok,org.entity_id}
        {:error,reason} -> {:error,reason}
    end
  end

  def create_prototypes() do
    titles = Application.fetch_env!(Puzzlespace.Permissions, :titles)
    structures = Application.fetch_env!(Puzzlespace.Permissions, :structures)
                |> Map.put("Title",titles)
    multi = Multi.new()
    |> Prototype.batch_insert(Prototype.create_prototype_orgs(structures))
    |> Prototype.batch_insert(Prototype.title_creators(structures))
    |> IO.inspect
    multi
    |> Puzzlespace.Repo.transaction()
  end


  def batch_insert(%Multi{} = multi,list) do
    Enum.reduce(list,multi,
      fn {name,changeset},multi ->
        Multi.insert_or_update(multi,name,changeset)
      end
    )
  end

  def create_prototype_orgs(structures) do
    structures
    |> Enum.map(
      fn {name,_titles} -> {name,Prototype.create_prototype_org(name)} end
    )
  end

  def create_prototype_org(name) do
    case Org.from_name(name <> "Prototype") do
      {:ok, protorg} -> Org.changeset(protorg,%{})
      {:error, _} -> 
        Org.changeset(%Org{},%{name: name <> "Prototype"})
        |> put_assoc(:org_entity,Entity.changeset(%Entity{},%{type: "prototype"}))
    end
  end

  def title_creators(structures) do
    Enum.map(structures, 
      fn {orgname,titles} ->
        Enum.map(titles,
          fn {title,permissions} ->
            {
              orgname <> ":" <> title,
              fn %{^orgname => org} ->
                Prototype.create_title(org,title,permissions) 
              end
            }
          end
        )
      end
    )
    |> List.flatten()
  end

  def create_title(%Org{} = org,title,permissions) do
    Puzzlespace.Relationship.create_title(
      org.entity_id,
      title,
      permissions,
      :changeset
    ) 
  end
end
