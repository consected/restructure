module ProtocolSupport
  include MasterSupport
  def list_valid_attribs
    res = []
    
    (1..5).each do |l|
      res << {
        name: "Classification::Protocol #{l}",
        position: 50+l*3,        
        disabled: false
      }
    end
    (1..5).each do |l|
      res << {
        name: "Dis Classification::Protocol #{l}",
        position: 100+l*3,        
        disabled: true
      }
    end
    res
  end
  
  def list_invalid_attribs
    [
      {
        name: nil
      }      
    ]
  end
  
  def list_invalid_update_attribs
    [      
      
      {
        name: nil
      }
    ]
  end  
  
  def new_attribs
    @new_attribs = {      
      position: 103,
      disabled: true
    }
  end
  
  
  
  def create_item att=nil, admin=nil
    att ||= valid_attribs    
    att[:current_admin] = admin||@admin
    
    @protocol = Classification::Protocol.create! att
  end
  
end
