module ReportsHelper

  def report_field name, type, value
    
    if type.is_a? String    
      type_string = type
      return nil
    elsif type.is_a? Hash
      type_string = type.first.first
      type_val = type.first.last      
      c = type_string.to_s.classify.constantize rescue nil
    end
      
    use_dropdown = nil    
    
    
    value ||= Report.calculate_default(type_val['default'], type_string)
    
    if c && c.respond_to?(:all_name_value_enable_flagged) 
      if type_val['item_type'] == 'all'
        type_filter = nil     
      elsif type_val['item_type']
        type_filter = {item_type: type_val['item_type']}
      end  
      logger.info "Use Dropdown for Select: #{type_filter}... #{type_val.inspect}"      
      use_dropdown = options_for_select(c.all_name_value_enable_flagged(type_filter), value)
      
    end
    
    if type_val['label']
      main_field = label_tag type_val['label']
    else
      main_field = label_tag name 
    end
    
    
    if type_val['multiple'] == 'multiple'
      if use_dropdown 
        main_field << select_tag("search_attrs[#{name}]", use_dropdown , multiple: true)
      else
        main_field << text_field_tag("multiple_attrs[#{name}]", '', type: type_string, class: 'form-control no-auto-submit'  , data: {attribute: name})
        main_field << link_to( "+", "add_multiple_attrs[#{name}]", data: {attribute: name}, class: 'btn btn-default add-btn', title: 'add to search')
        v = value
        v = value.join("\n") if value.is_a? Array
        main_field << text_area_tag("search_attrs[#{name}]", v, class: 'auto-grow')
        
      end
    else 
      if use_dropdown 
        main_field << select_tag("search_attrs[#{name}]", use_dropdown , include_blank: 'select')
      else
        main_field << text_field_tag("search_attrs[#{name}]", value, type: type_string, class: 'form-control' )
      end
    end
    
    
    
    
  end

    
end
