module SubProcessSupport
  include MasterSupport
  def list_valid_attribs
    res = []
    
    (1..5).each do |l|
      res << {
        name: "SubProcess #{l}",
        
        disabled: false,
        protocol_id: @protocol_id
      }
    end
    (1..5).each do |l|
      res << {
        name: "Dis SubProcess #{l}",
        
        disabled: true,
        protocol_id: @protocol_id
      }
    end
    res
  end
  
  def list_invalid_attribs
    [
      {
        name: nil,
        protocol_id: @protocol_id
      }       
    ]
  end
  
  def list_invalid_update_attribs
    [            
      {
        name: nil,
        protocol_id: @protocol_id
      }
    ]
  end  
  
  def new_attribs
    @new_attribs = {            
      disabled: true,
        protocol_id: @protocol_id
    }
  end
  
  
  
  def create_item att=nil, admin=nil
    att ||= valid_attribs    
    att[:current_admin] = admin||@admin
    
    @sub_process = @protocol.sub_processes.create! att
  end
  
end
