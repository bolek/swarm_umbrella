defmodule SwarmEngine.Message do
  alias SwarmEngine.Util.UUID

  defstruct [:id, :body, :headers]

  def create(body, headers) do
    %SwarmEngine.Message{
      id: UUID.generate(),
      headers: headers,
      body: body
    }
  end
end
