defmodule SwarmEngine.Adapters.GoogleAuth.Goth do
  def get_token(scope) do
    Goth.Token.for_scope(scope)
  end
end
