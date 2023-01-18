module ActivityLogSupport
  include MasterSupport

  def gen_activity_log_path(master_id, item_id, id = nil)
    res = "/masters/#{master_id}/player_contacts/#{item_id}/activity_log/player_contact_phones"
    res += "/#{id}" if id
    res
  end

  #
  # Add a model references definition to an existing activity log instance,
  # to simplify the configuration required for certain tests
  # e.g add_reference_def_to(activity_log, [player_contacts: { from: 'this', add: 'many' }])
  def add_reference_def_to(activity_log, ref_def)
    activity_log.option_type_config.references = ref_def
    activity_log.option_type_config.clean_references_def
  end


  def generate_test_activity_log
    unless Admin::MigrationGenerator.table_exists? 'activity_log_player_contact_emails'
      TableGenerators.activity_logs_table('activity_log_player_contact_emails', 'player_contacts', true, 'emailed_when')
    end

    setup_access :masters, user: @user
    @master = Master.create! current_user: @user
    @master.current_user = @user

    ActivityLogSupport.cleanup_matching_activity_logs('player_contact', 'email', nil, admin: @admin)
    al = ActivityLog.create! current_admin: @admin,
                             name: 'activity_log_player_contact_emails',
                             item_type: 'player_contact',
                             rec_type: 'email',
                             action_when_attribute: 'emailed_when',
                             field_list: 'data, select_call_direction, select_who, emailed_when, select_result, select_next_step, follow_up_when, notes, protocol_id',
                             blank_log_field_list: 'select_who, emailed_when, select_next_step, follow_up_when, notes, protocol_id'

    al.current_admin = @admin
    al.update_tracker_events

    expect(al).to be_a ::ActivityLog

    refresh_step_access al

    al
  end

  def refresh_step_access(al_def)
    setup_access :activity_log__player_contact_emails, user: @user
    setup_access :activity_log__player_contact_emails, user: @user0 if @user0

    al_def.option_configs.each do |c|
      rn = c.resource_name

      setup_access rn, resource_type: :activity_log_type, user: @user
      setup_access rn, resource_type: :activity_log_type, user: @user0 if @user0

      res = @user.has_access_to? :access, :activity_log_type, rn
      expect(res).to be_truthy
    end
  end

  def list_valid_attribs
    @player_contact = PlayerContact.last

    unless @player_contact
      setup_access :player_contacts, user: @master.current_user

      @player_contact = @master.player_contacts.create!(
        {
          data: '(516)262-1289',
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
        select_call_direction: 'to staff',
        select_who: 'user',
        extra_log_type: 'primary'

      },
      {
        player_contact_id: @player_contact.id,
        select_call_direction: 'to player',
        select_who: 'user',
        extra_log_type: 'primary'
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

  def create_item(att = nil, _item = nil)
    setup_access :player_contacts, user: @user
    att ||= valid_attribs
    # master ||= @master || @player_contact.master
    # item ||= @player_contact
    # att[:player_contact] = item
    att[:master] ||= @player_contact.master
    @player_contact.current_user = @user

    setup_access :activity_log__player_contact_phones, user: @user
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, user: @user
    setup_access :activity_log__player_contact_phone__blank, resource_type: :activity_log_type, user: @user

    @activity_log = @player_contact.activity_log__player_contact_phones.create! att
  end

  def create_al_for_resource_name(resource_name, att = nil)
    setup_access :player_contacts, user: @user
    att ||= valid_attribs
    # master ||= @master || @player_contact.master
    # item ||= @player_contact
    # att[:player_contact] = item
    att[:master] ||= @player_contact.master
    @player_contact.current_user = @user

    setup_access resource_name, user: @user
    setup_access "#{resource_name.singularize}__primary".to_sym, resource_type: :activity_log_type, user: @user
    setup_access "#{resource_name.singularize}__blank".to_sym, resource_type: :activity_log_type, user: @user

    @activity_log = @player_contact.send(resource_name).create! att
  end

  def mock_send_sms_response(notification_inst)
    allow(notification_inst).to receive(:send_sms) do |_sms_number, _msg_text, _importance|
      resp = Aws::SNS::Types::PublishResponse.new
      resp.message_id = "MOCK-#{rand 1_000_000_000}"
      resp
    end
  end

  def self.cleanup_matching_activity_logs(item_type, rec_type, process_name, excluding_id: nil, admin: nil)
    process_name = ['', nil] if process_name.blank?
    others = ActivityLog.works_with_all(item_type, rec_type, process_name)
    others = others.where.not(id: excluding_id) if excluding_id
    others.each do |o|
      o.update!(disabled: true, current_admin: admin || o.admin)
    end
  end
end
