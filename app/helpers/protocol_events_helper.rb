module ProtocolEventsHelper

  def protocol_events_array_with_class
    res = ProtocolEvent.selector_attributes [:name, :protocol_id]
    
    res = res.map {|a| [a.first, a.first, {"data-filter-id" => a.last}]}
    
    res = add_all_to_options(res, '(all events)')
    
    res
  end
  
  def protocol_outcomes_array_with_class
    res = ProtocolOutcome.selector_attributes [:name, :protocol_id]
    
    res = res.map {|a| [a.first, a.first, {"data-filter-id" => a.last}]}
    
    res = add_all_to_options(res, '(all outcomes)')
    
    res
  end
  

  protected
    def add_all_to_options options, label
      i = 0
      prev = ''
      options.dup.each do |e|
        
        dfid = e.last['data-filter-id'].to_s
        logger.debug ">>>>> #{prev} ?= #{dfid}"
        if(dfid != prev.to_s)
          # Force sending a space character which will be parsed out server side
          # Not an ideal long term solution, but works for now.
          logger.debug ">>>>> #{prev} != #{dfid}"
          options.insert i, [label, ' ', {"data-filter-id" => dfid} ]
          prev = dfid
        end 
        i+=1
      end
      
      return options
    end
end
