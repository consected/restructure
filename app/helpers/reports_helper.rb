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
    
    
    value ||= type_val['default']
    
    if c && c.respond_to?(:selector_cache?) && c.selector_cache?      
      if type_val['filter'] == 'all'
        type_filter = nil     
      else
        type_filter = type_val['filter']
      end  
            
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
        main_field << text_field_tag("multiple_attrs[#{name}]", value, type: type_string, class: 'form-control'  , data: {attribute: name})
        main_field << link_to( "+", "add_multiple_attrs[#{name}]", data: {attribute: name}, class: 'btn btn-default')
        
        main_field << text_area_tag("search_attrs[#{name}]", value.join("\n"))
        
      end
    else 
      if use_dropdown 
        main_field << select_tag("search_attrs[#{name}]", use_dropdown )
      else
        main_field << text_field_tag("search_attrs[#{name}]", value, type: type_string, class: 'form-control' )
      end
    end
    
    
    
    
  end


end
