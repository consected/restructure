module ActivityLogSupport

  include MasterSupport

  def gen_activity_log_path master_id, item_id, id=nil
    res = "/masters/#{master_id}/player_contacts/#{item_id}/activity_log/player_contact_phones"
    res += "/#{id}" if id
    res
  end

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
        player_contact_id: @player_contact.id,
        select_call_direction: 'from player',
        select_who: 'user'
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
        player_contact_id: @player_contact.id,
        select_call_direction: 'to player',
        select_who: 'user'
      }
  end



  def create_item att=nil, item=nil
    att ||= valid_attribs
    master ||= create_master
    item ||= @player_contact
    att[:player_contact] = item
    item.master.current_user ||= @user || create_user
    item.master_user.app_type ||= Admin::AppType.active.first

    setup_access :activity_log__player_contact_phones
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type
    setup_access :activity_log__player_contact_phone__blank, resource_type: :activity_log_type
    
    @activity_log = master.activity_log__player_contact_phones.create! att

  end

end
