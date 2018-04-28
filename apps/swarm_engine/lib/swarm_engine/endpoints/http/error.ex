defmodule SwarmEngine.Endpoints.HTTP.Error do
  alias __MODULE__

  defexception [:message]

  def exception({url, reason}) do
    msg = "requesting #{url}, got: #{Kernel.inspect(reason)}"
    %Error{message: msg}
  end

  def exception(url) do
    msg = "error when requesting #{url}"
    %Error{message: msg}
  end
end
