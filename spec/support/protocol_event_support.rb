module ProtocolEventSupport
  include MasterSupport
  def list_valid_attribs

    instance_var_init :sub_process_id
    
    res = []
    
    (1..5).each do |l|
      res << {
        name: "Protocol Event #{l}",
        
        disabled: false,
        
        sub_process_id: @sub_process_id
      }
    end
    (1..5).each do |l|
      res << {
        name: "Dis Protocol Event #{l}",
        
        disabled: true,
        
        sub_process_id: @sub_process_id
      }
    end
    res
  end
  
  def list_invalid_attribs
    instance_var_init :sub_process_id

    [
      {
        name: nil,
        
        sub_process_id: @sub_process_id
      }       
    ]
  end
  
  def list_invalid_update_attribs
    instance_var_init :sub_process_id

    [            
      {
        name: nil,
        
        sub_process_id: @sub_process_id
      }
    ]
  end  
  
  def new_attribs
    @new_attribs = {            
      disabled: true,
        
        sub_process_id: @sub_process_id
    }
  end
  
  
  
  def create_item att=nil, admin=nil
    att ||= valid_attribs    
    att[:current_admin] = admin||@admin
    
    @protocol_event = @sub_process.protocol_events.create! att
  end
  
end
