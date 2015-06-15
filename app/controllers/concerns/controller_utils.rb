module ControllerUtils
  
  extend ActiveSupport::Concern

  def params_nil_if_blank p
    p1 = p.dup
    p.each do |k,v|     
      
      if v.is_a? Hash
        p1[k] = params_nil_if_blank v 
      elsif v.blank?
        p1[k] = nil        
      end
    end
    
    p1
  end

  def params_downcase p
    p1 = p.dup
    p.each do |k,v|           
      if v.is_a? Hash
        p1[k] = params_downcase v 
      elsif v.is_a?(String) && !v.blank?
        p1[k] = v.downcase        
      end
    end
    
    p1
  end
  

  
end
