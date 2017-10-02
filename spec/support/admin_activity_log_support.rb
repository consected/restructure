module AdminActivityLogSupport

  include MasterSupport

  def list_valid_attribs

    [
      {
        name: "Test Log",
        item_type: 'player_contacts',
        rec_type: 'phone',
        action_when_attribute: 'called_when',
        current_admin: @admin
      }
    ]


  end

  def list_invalid_attribs
    [
      {
        name: "",
        item_type: 'player_contacts',
        rec_type: 'phone',
        action_when_attribute: 'called_when',
        current_admin: @admin
      },
      {
        name: "Test Log",
        item_type: 'player_contacts_not_exist',
        rec_type: 'phone',
        action_when_attribute: 'called_when',
        current_admin: @admin
      },
      {
        name: "Test Log",
        item_type: 'player_contacts',
        rec_type: 'bad',
        action_when_attribute: 'called_when',
        current_admin: @admin
      }
    ]
  end

  def list_invalid_update_attribs
    [

      {
        item_type: 'player_contacts_not_exist',
        current_admin: @admin
      }
    ]
  end

  def new_attribs

    @new_attribs = {
      name: "test log",
      item_type: 'player_contacts',
      rec_type: 'phone',
      action_when_attribute: 'called_when',
      current_admin: @admin
    }
  end

  def create_item att=nil, admin=nil
    att ||= valid_attribs
    att[:current_admin] ||= admin  if admin.is_a? Admin
    raise "No admin set" unless att[:current_admin]
    @activity_log = ActivityLog.create! att
  end

end
