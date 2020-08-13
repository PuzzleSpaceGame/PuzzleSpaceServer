defmodule Debug do
  def write_to_file(x,filename) do
    IO.puts "Writing to debug file #{filename}"
    File.open!(filename,[:write],fn file ->
        IO.write(file,x)
    end)
    x
  end
end
