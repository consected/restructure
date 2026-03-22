module GeneralSelectionsHelper
  def general_selection_block_id(item_type)
    "##{item_type}-definitions-#{@id}"
  end

  def general_selection(type, options = {})
    type = type.to_sym if type.is_a? String

    @gs_item_types ||= {}
    @gs_item_types[type] = !!Classification::GeneralSelection.item_types.include?(type) if @gs_item_types[type].nil?
    inc = @gs_item_types[type]

    unless options[:use_like] || inc
      return nil if options[:quiet_fail]

      raise "Item type not recognized: #{type}"
    end

    cond = if options[:use_like]
             ['item_type LIKE ?', type]
           else
             { item_type: type }
           end

    attr = %i[name value create_with edit_if_set edit_always lock description]

    @selattr ||= {}
    res_attr = @selattr[cond] ||= Classification::GeneralSelection.selector_attributes(attr, cond)

    if @id
      # Get results to check if the item is set to lock, and the value is set
      res = res_attr.select { |a| !!a[5] && a[1] == options[:value] }
      # If the current value is not set to lock, check for edit_always or edit_if_set and the value is that set
      res  = res_attr.select { |a| !!a[4] || !!a[3] && a[1] == options[:value] } if res.length == 0
    else
      res  = res_attr.select { |a| !!a[2] }
    end

    res.collect! { |a| [a[0], a[1]] } unless options[:return_all]

    res.map! { |a| ["#{a[1]} - #{a[0]}", a[1]] } if options[:present] == :hyphenate_name_val
    res.sort! { |a, b| a[1].to_i <=> b[1].to_i } if options[:order] == :value_number
    res.sort! { |a, b| b[1].to_i <=> a[1].to_i } if options[:order] == :value_number_desc

    res
  end

  def general_selection_cache_names
    all_cnames = []

    # Preload all of the general selections into cache so they can be used
    # This pulls dynamic model and activity log extra log types as separate items
    implementation_classes = ActivityLog.implementation_classes

    # Check the definition is ready to use and prepare it for use
    implementation_classes.select! { |ic| ic.definition.ready_to_generate? }
    implementation_classes.each do |itc|
      next unless itc.allows_user_access_to?(current_user, :access)

      ito = itc.new
      cnames = if itc.respond_to?(:option_configs)
                 itc.option_configs.map { |k| "general_selections-item_type+#{ito.item_type}-extra_log_type+#{k.name}" }
               else
                 ["general_selections-item_type+#{ito.item_type}"]
               end

      all_cnames += cnames
    end

    implementation_classes = DynamicModel.implementation_classes
    implementation_classes.select! { |ic| ic.definition.ready_to_generate? }
    cnames = []

    full_names = implementation_classes.map { |itc| "dynamic_model__#{itc.definition.implementation_model_name}" }
    res = Admin::UserAccessControl.access_for_list?(current_user, :access, :table, full_names)
    implementation_classes.each do |itc|
      full_name = "dynamic_model__#{itc.definition.implementation_model_name}"
      next unless res[full_name.to_sym]

      ito = itc.new
      cnames.push("general_selections-item_type+#{ito.item_type}")
    end
    all_cnames += cnames

    all_cnames.flatten
  end
end
