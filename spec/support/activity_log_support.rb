module ActivityLogSupport
  
  include MasterSupport
  
  
  def list_valid_attribs
    
    
    @player_contact = PlayerContact.last

    

    unless @player_contact
      @player_contact = @master.player_contacts.create!(
      {
        data: "(516)262-1289",
        source: 'nfl',
        rank: 10,
        rec_type: 'phone'
      }
      )
      @player_contact = PlayerContact.last
    end
    
    [
      {
        item_id: @player_contact.id,
        item_type: 'PlayerContact'
      }
    ]
    
    
  end
  
  def list_invalid_attribs
    create_master
    create_item
    create_item_flag_name 'PlayerContact'
    [
      {
        master_id: @player_contact.master_id,
        item_controller: 'player_contacts',
        item_id: @player_contact.id                 
      }
      
      
    ]
  end
  
  def list_invalid_update_attribs
    [      
            
      {
        item_type: 'player_contact'
      }
    ]
  end  
  
  def new_attribs
    create_item
    @new_attribs = {
        item_id: @player_contact.id,
        item_type: 'PlayerContact'
      }
  end
  
  
  
  def create_item att=nil, item=nil
    att ||= valid_attribs    
    att[:user] ||= @user
    item ||= @player_contact
    @activity_log = item.activity_logs.create! att
  end
  
end
