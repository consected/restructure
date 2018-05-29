module ProtocolsHelper

  def protocol_array
    res = Classification::Protocol.selector_array_pair
    res
  end

  def protocol_array_without_updates
    res = Classification::Protocol.selector_array_pair.reject {|a| a.first == Classification::Protocol::RecordUpdatesProtocolName}
    res
  end

  def sub_processes_array
    res = Classification::SubProcess.selector_attributes [:name, :id, :protocol_name]
    res  = res.map {|a| ["#{a.last} - #{a.first}", a[1]]}
    res
  end


  def sub_processes_array_with_class
    res = Classification::SubProcess.selector_attributes [:name, :id, :protocol_id]

    res = res.map {|a| [a.first, a[1], {"data-filter-id" => a.last}]}

    res
  end

  def protocol_events_array_with_class options={}
    res = Classification::ProtocolEvent.selector_attributes [:name, :id, :sub_process_id]

    pes = res.collect {|a| a[2]}

    if options[:add_empty]
      # look for missing items
      missing = []
      sub_processes_array.each do |a|
        missing << [options[:add_empty], '(null)', {"data-filter-id" => a[1]} ] unless pes.include? a[1]
      end

    end


    res = res.select {|a| a.last}.map {|a| [a.first, a[1], {"data-filter-id" => a.last}]}

    res += missing if missing

    res
  end

  def protocol_events_name_array_with_class
    res = Classification::ProtocolEvent.selector_attributes [:name, :sub_process_id]

    res = res.map {|a| [a.first, a.first.downcase, {"data-filter-id" => a.last}]}

    res
  end



end
