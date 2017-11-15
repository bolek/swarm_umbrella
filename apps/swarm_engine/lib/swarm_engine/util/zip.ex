defmodule SwarmEngine.Util.Zip do

  def unzip(filepath, options \\ []), do: :zip.unzip(filepath, options)

  def zipped?(filepath) do
    with  {:ok, file}   <- :file.open(filepath, [:read, :binary]),
          {:ok, header} <- :file.read(file, 4),
           :ok          <- :file.close(file)
    do
      zip_header?(header)
    end
  end

  defp zip_header?(<<0x50, 0x4B, 0x03, 0x04>>), do: true
  defp zip_header?(<<0x50, 0x4B, 0x05, 0x06>>), do: true
  defp zip_header?(_),                          do: false
end
