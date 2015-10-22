module ItemFlagNamesHelper


  def item_types_array    
    ItemFlag.use_with_class_names.collect {|v| v.singularize.underscore}
  end
  
end
