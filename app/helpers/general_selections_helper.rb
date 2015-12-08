module GeneralSelectionsHelper

  def general_selection_block_id item_type
    "##{item_type}-definitions-#{@id}"
  end
  
  def general_selection type, options={}
    raise "Item type not recognized" unless GeneralSelection.item_types.include? type
    
    cond = {item_type: type}
    attr = [:name, :value, :create_with, :edit_if_set, :edit_always, :lock, :description]
    res_attr = GeneralSelection.selector_attributes(attr, cond)
        
    if @id
      # Get results to check if the item is set to lock, and the value is set 
      res = res_attr.select {|a| !!a[5] && a[1] == options[:value]}
      # If the current value is not set to lock, check for edit_always or edit_if_set and the value is that set
      res  = res_attr.select {|a| !!a[4] || !!a[3] && a[1] == options[:value] } if res.length == 0
    else
      res  = res_attr.select {|a| !!a[2]}
    end
    
    unless options[:return_all]      
      res.collect! {|a| [a[0], a[1]]} 
    end
    
    
    res.map! {|a| ["#{a[1]} - #{a[0]}", a[1]]} if options[:present] == :hyphenate_name_val
    res.sort! {|a,b| a[1].to_i <=> b[1].to_i} if options[:order] == :value_number
    res.sort! {|a,b| b[1].to_i <=> a[1].to_i} if options[:order] == :value_number_desc
    
    res
    
  end

end
