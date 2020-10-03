defmodule Mix.Tasks.Loadprototypes do
  use Mix.Task

  @shortdoc "Updates relationship prototypes"
  def run(_) do
    Mix.Task.run("app.start")
    Puzzlespace.Permissions.Prototype.create_prototypes()
    |> IO.inspect
  end
end
