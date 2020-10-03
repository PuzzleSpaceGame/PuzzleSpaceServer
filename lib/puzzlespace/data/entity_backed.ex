defprotocol Puzzlespace.EntityBacked do
  @doc "String representation"
  def name(ebs)
  @doc "URL for EBS profile"
  def url(ebs)
end
