module ItemFlagSupport
  include MasterSupport
  
  def create_item_flag_name item_type
    ifn = ItemFlagName.create! name: "IFN #{Time.new.to_f} #{rand 1000000000}", current_admin: @admin, item_type: item_type
    @item_flag_name = ifn
  end
  
  def list_valid_attribs
    res = []
    
    create_item_flag_name 'PlayerInfo'
    
    @player_info = PlayerInfo.last
    [
      {
        item_id: @player_info.id,
        item_type: 'PlayerInfo',
        item_flag_name_id: @item_flag_name.id
      }
    ]
    
    
  end
  
  def list_invalid_attribs
    create_master
    create_item
    create_item_flag_name 'PlayerInfo'
    [
      {
        master_id: @player_info.master_id, 
        item_controller: 'player_infos', 
        item_id: @player_info.id, 
        item_flag: {
          item_flag_name_id: [-4]
        }         
      }
      
      
    ]
  end
  
  def list_invalid_update_attribs
    [      
            
      {
        item_type: 'player_info'        
      }
    ]
  end  
  
  def new_attribs
    create_item
    @new_attribs = {
        item_id: @player_info.id,
        item_type: 'PlayerInfo',
        item_flag_name_id: @item_flag_name.id
      }
  end
  
  
  
  def create_item att=nil, item=nil
    att ||= valid_attribs    
    att[:user] ||= @user
    item ||= @player_info 
    @item_flag = item.item_flags.create! att
  end
  
end
