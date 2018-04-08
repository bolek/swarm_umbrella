defmodule SwarmEngine.Test.FileHelper do
  def modified_at(path) do
    path
    |> File.stat!()
    |> Map.get(:mtime)
    |> NaiveDateTime.from_erl!()
  end
end
