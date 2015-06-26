module ProtocolEventsHelper

  def protocol_events_array_with_class
    res = ProtocolEvent.selector_attributes [:name, :protocol_id]
    
    res = res.map {|a| [a.first, a.first, {"data-protocol-id" => a.last}]}
    
    res
  end

end
