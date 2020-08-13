defmodule Parallel do
  def map(collection, func) when is_function(func,1) do
    collection
    |> Enum.map(&(Task.async(fn -> func.(&1) end)))
    |> Enum.map(&Task.await/1)
  end
end
