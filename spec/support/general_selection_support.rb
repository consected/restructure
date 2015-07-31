module GeneralSelectionSupport
  include MasterSupport
  def list_valid_attribs
    res = []
    
    (1..5).each do |l|
      res << {
        name: "Score #{l}",
        value: "val#{l}",
        item_type: "addresses_type",
        disabled: false
      }
    end
    (1..5).each do |l|
      res << {
        name: "DisScore #{l}",
        value: "disval#{l}",
        item_type: "addresses_type",
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
        value: nil
      },
      {
        item_type: nil 
      },
      {
        item_type: 'unknown'
      }
    ]
  end
  
  def list_invalid_update_attribs
    [      
      
      {
        value: nil
      },
      {
        value: 'any change'        
      },
      {
        item_type: nil
      },
      {
        item_type: 'player_contacts_type'
      }
    ]
  end  
  
  def new_attribs
    @new_attribs = {
      name: 'alt 1'      
    }
  end
  
  
  
  def create_item att=nil, master=nil
    att ||= valid_attribs    
    
    @general_selection = GeneralSelection.create! att
  end
  
end
