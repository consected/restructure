module ProtocolsHelper

  def protocol_array
    res = Protocol.selector_array_pair
    res
  end

  def protocol_array_without_updates
    res = Protocol.selector_array_pair.reject {|a| a.first == Protocol::RecordUpdatesProtocolName}
    res
  end

  def sub_processes_array
    res = SubProcess.selector_attributes [:name, :id, :protocol_name]
    res  = res.map {|a| ["#{a.last} - #{a.first}", a[1]]}
    res
  end

  
  def sub_processes_array_with_class
    res = SubProcess.selector_attributes [:name, :id, :protocol_id]
    
    res = res.map {|a| [a.first, a[1], {"data-filter-id" => a.last}]}
    
    res
  end
  
  def protocol_events_array_with_class
    res = ProtocolEvent.selector_attributes [:name, :id, :sub_process_id]
    
    res = res.map {|a| [a.first, a[1], {"data-filter-id" => a.last}]}
    
    res
  end
  
  def protocol_events_name_array_with_class
    res = ProtocolEvent.selector_attributes [:name, :sub_process_id]
    
    res = res.map {|a| [a.first, a.first.downcase, {"data-filter-id" => a.last}]}
    
    res
  end
  
  def protocol_outcomes_array_with_class
    res = ProtocolOutcome.selector_attributes [:name, :protocol_id]
    
    res = res.map {|a| [a.first, a.first.downcase, {"data-filter-id" => a.last}]}
    
    #res = add_all_to_options(res, '(all outcomes)')
    
    res
  end
  

  protected
  
    # Every filter-id in the filtered select options should gain an extra item with a 
    # value (default single space ' ') 
    # Simply sort the list by data-filter-id, then every change add the extra item at the 
    # top of the original array. On filtering, the corresponding additional item will appear
    # at the top of the list.
    # The default of sending a space character which will be parsed out server side, while ensuring that
    # null  / blank logic in javascript will see a value has been entered.
    # Not an ideal long term solution, but works for now.
          
    def add_all_to_options options, label, data_value = ' '
      i = 0
      prev = ''
      options.sort_by {|a| a.last['data-filter-id'].to_s}.each do |e|
        
        dfid = e.last['data-filter-id'].to_s
        
        if(dfid != prev.to_s)
          
          options.insert 0, [label, data_value, {"data-filter-id" => dfid} ]
          prev = dfid
        end 
        i+=1
      end
      
      return options
    end

end
