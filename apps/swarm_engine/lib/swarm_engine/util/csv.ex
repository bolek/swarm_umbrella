defmodule SwarmEngine.Util.CSV do
  def decode!(params, options \\ []), do:
    CSV.decode!(params, convert_options(options))

  defp convert_options(options) do
    cond do
      Keyword.has_key?(options, :separator) ->
        {_, new} = Keyword.get_and_update!(options, :separator, &separator_codepoint/1)
        new

      true ->
        options
    end
  end

  defp separator_codepoint(<<separator::utf8>> = current), do:
    {current,  separator}
end
