defmodule Puzzlespace.Relationship do
  use Puzzlespace.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  require Puzzlespace.Repo
  alias Ecto.Multi
  alias Puzzlespace.Entity
  alias Puzzlespace.Relationship

  schema "relationships" do
    belongs_to :primary, Entity
    field :title, :string
    belongs_to :reciever, Entity
    field :permissions, EctoListOfStringTuple
    field :perm_map, :map, virtual: true
    timestamps()
  end


  def changeset(%Puzzlespace.Relationship{}=relationship,params) do
    IO.inspect(params)
    relationship
    |> cast(params,[:primary_id,:title,:reciever_id,:permissions])
    |> validate_required([:primary_id,:title,:reciever_id,:permissions])
    |> unique_constraint(:primary_id, name: :"duplicate title assignment")
  end

  def create_title(primary,title,permissions,action \\ :insert)
  def create_title(%Entity{} = primary,title,permissions,action) do
    create_title(primary.id,title,permissions,action)
  end
  def create_title(primary_id,title,permissions,:changeset) do
    Puzzlespace.Relationship.changeset(%Puzzlespace.Relationship{},
      %{primary_id: primary_id, title: title, 
        reciever_id: primary_id, permissions: permissions
      })
  end
  def create_title(primary_id,title,permissions,:insert) do
    create_title(primary_id,title,permissions,:changeset)
    |> Puzzlespace.Repo.insert()
  end

  def inherit_title(prototype_id,inheritor_id,prototype_title,inherited_title,action \\ :insert) do
    permissions = 
      (from r in Puzzlespace.Relationship,
        where: r.primary_id == ^prototype_id and r.reciever_id == ^prototype_id and r.title == ^prototype_title,
        select: r.permissions)
        |> Puzzlespace.Repo.one()
    Relationship.create_title(inheritor_id,inherited_title,permissions,action)
  end

  def assign_title(primary_id,title,reciever_id, action \\ :insert)
  def assign_title(primary_id,title,reciever_id,:changeset) do
    perms = (from r in Puzzlespace.Relationship,
      where: r.primary_id == ^primary_id and r.reciever_id == ^primary_id and r.title == ^title,
      select: r.permissions)
      |> Puzzlespace.Repo.one()
    Puzzlespace.Relationship.changeset(%Puzzlespace.Relationship{},%{primary_id: primary_id, reciever_id: reciever_id, title: title, permissions: perms})
  end
  def assign_title(primary_id,title,reciever_id,:insert) do
    assign_title(primary_id,title,reciever_id,:changeset)
    |> Puzzlespace.Repo.insert()
  end

  def inherit_structure(prototype_id,inheritor_id,:multi) do
    (from r in Puzzlespace.Relationship,
      where: r.primary_id == ^prototype_id and r.reciever_id == ^prototype_id,
      select: {r.title,r.permissions})
      |> Puzzlespace.Repo.all()
      |> Enum.map(fn {title,permissions} -> Puzzlespace.Relationship.create_title(inheritor_id,title,permissions,:changeset) end)
      |> Enum.reduce(Multi.new(),fn changeset,multi -> Multi.insert(multi,changeset.changes.title,changeset,on_conflict: :replace_all,conflict_target: [:primary_id,:reciever_id,:title]) end)
  end

  def inherit_structure(proto,inheritor,:insert), do: inherit_structure(proto,inheritor)
  def inherit_structure(prototype_id,inheritor_id) do
    Puzzlespace.Relationship.inherit_structure(prototype_id,inheritor_id,:multi)
    |> Puzzlespace.Repo.transaction()
  end

  def get_raw_permissions(entity_id) do
    (from r in Puzzlespace.Relationship,
      where: r.reciever_id == ^entity_id,
      select: {r.primary_id,r.permissions})
    |> Puzzlespace.Repo.all()
    |> Enum.reduce(%{},
      fn {primary_id,permissions},map -> 
        Map.update(
          map,
          (if primary_id == entity_id, do: :self, else: primary_id),
          permissions,
          &(&1 ++ permissions)
        )
      end)
  end
  
  def clean_permissions(permissions) do
    permissions
    |> Enum.reduce(permissions,
      fn {_primary_entity_id,perms},updated_permissions -> 
        Enum.reduce(perms,updated_permissions,
          fn perm,perm_map -> 
            case Tuple.to_list(perm) do
              ["id:" <> aux_entity_id | permission ] -> 
                Map.update(perm_map,aux_entity_id,[List.to_tuple(permission)],&(&1 ++ [List.to_tuple(permission)]))
              _ -> perm_map
            end
          end
        )
      end)
  end

  def get_permissions(entity_id) do
    Puzzlespace.Relationship.get_raw_permissions(entity_id)
    |> Puzzlespace.Relationship.clean_permissions()
  end

  def load_permissions(%Entity{} = entity) do
    %{entity | perm_map: get_permissions(entity.id)}
  end

end
