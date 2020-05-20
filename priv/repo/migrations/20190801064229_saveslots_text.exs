defmodule Puzzlespace.Repo.Migrations.SaveslotsText do
  use Ecto.Migration

  def change do
    alter table(:saveslots) do
        modify :savedata, :text
    end
  end
end
