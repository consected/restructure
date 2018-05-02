module ItemFlagNameSupport
  include MasterSupport
  def list_valid_attribs
    res = []
    
    (1..5).each do |l|
      res << {
        name: "Flag #{l}",
        
        item_type: "player_info",
        disabled: false
      }
    end
    (1..5).each do |l|
      res << {
        name: "Dis Flag #{l}",
        
        item_type: "player_info",
        disabled: true
      }
    end
    res
  end
  
  def list_invalid_attribs
    [
      {
        name: nil
      },
      {
        item_type: nil 
      }
    ]
  end
  
  def list_invalid_update_attribs
    [      
            
      {
        item_type: 'pro_info'        
      }
    ]
  end  
  
  def new_attribs
    @new_attribs = {
      name: 'alt 1',      
      item_type: 'player_info'
    }
  end
  
  
  
  def create_item att=nil, admin=nil
    att ||= valid_attribs    
    att[:current_admin] = admin||@admin 
    @item_flag_name = Admin::ItemFlagName.create! att
  end
  
end
