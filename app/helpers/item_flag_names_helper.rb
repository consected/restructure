module ItemFlagNamesHelper


  def item_types_array
    Master.reflect_on_all_associations(:has_many).collect {|v| v.plural_name.singularize}
    
  end
  
end
