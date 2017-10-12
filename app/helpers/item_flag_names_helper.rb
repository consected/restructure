module ItemFlagNamesHelper


  def item_types_array
    object_instance.class.use_with_class_names.collect {|v| v.singularize.ns_underscore}
  end

end
