module ProtocolsHelper

  def protocol_array
    res = Protocol.selector_array_pair
    res
  end
  
end
