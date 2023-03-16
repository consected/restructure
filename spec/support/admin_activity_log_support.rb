require './db/table_generators/activity_logs_table'

module AdminActivityLogSupport
  include MasterSupport

  def list_valid_attribs
    [
      {
        name: 'activity_log_player_contact_emails',
        item_type: 'player_contact',
        rec_type: 'email',
        action_when_attribute: 'emailed_when',
        current_admin: @admin
      }
    ]
  end

  def list_invalid_attribs
    [
      {
        name: '',
        item_type: 'player_contacts',
        rec_type: 'email',
        action_when_attribute: 'emailed_when',
        current_admin: @admin
      },
      {
        name: 'Test Log',
        item_type: 'player_contacts_not_exist',
        rec_type: 'email',
        action_when_attribute: 'emailed_when',
        current_admin: @admin
      },
      {
        name: 'Test Log',
        item_type: 'player_contacts',
        rec_type: 'bad',
        action_when_attribute: 'emailed_when',
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
      name: 'test_log',
      item_type: 'player_contact',
      rec_type: 'email',
      action_when_attribute: 'emailed_when',
      current_admin: @admin
    }
  end

  def create_item(att = nil, admin = nil)
    att ||= valid_attribs
    att[:current_admin] ||= admin if admin.is_a? Admin
    raise 'No admin set' unless att[:current_admin]

    tn = [att[:item_type]]
    tn << att[:rec_type] if att[:rec_type]
    tn = tn.join('_').pluralize

    ActivityLogSupport.cleanup_matching_activity_logs(att[:item_type], att[:rec_type], nil, admin: att[:current_admin])

    ActiveRecord::Base.connection.schema_cache.clear!
    unless ActivityLog.connection.table_exists? "activity_log_#{tn}"
      TableGenerators.activity_logs_table(tn, att[:item_type].pluralize, true, 'emailed_when')
    end
    @activity_log = ActivityLog.create! att
  end
end
