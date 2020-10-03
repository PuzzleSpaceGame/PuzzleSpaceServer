defmodule EctoListOfStringTuple do
  use Ecto.Type
  def type, do: {:array,{:array, :string}}

  def cast([content | _] = data) when is_list(data) and is_tuple(content) do
    {:ok,data}
  end
  def cast([]) do
    {:ok,[]}
  end
  def cast(_), do: nil

  def load(data) when is_list(data) do
    {:ok,Enum.map(data, fn x -> List.to_tuple(x) end)}
  end

  def dump(data) when is_list(data) do
    {:ok, Enum.map(data, fn x -> Tuple.to_list(x) end)}
  end
end
