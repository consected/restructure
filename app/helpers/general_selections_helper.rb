module GeneralSelectionsHelper

  def general_selection type, options={}
    raise "Item type not recognized" unless GeneralSelection::ItemTypes.include? type
    res = GeneralSelection.selector_name_value_pair(item_type: type)
    
    res.map! {|a| ["#{a.last} - #{a.first}", a.last]} if options[:present] == :hyphenate_name_val
    res.sort! {|a,b| a.last.to_i <=> b.last.to_i} if options[:order] == :value_number
    res.sort! {|a,b| b.last.to_i <=> a.last.to_i} if options[:order] == :value_number_desc
    
    res
    
  end

end
