defprotocol SwarmEngine.ConnectorProt do

  def request(source)
  def metadata(source)
  def list(source)
end
