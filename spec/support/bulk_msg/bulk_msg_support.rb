# frozen_string_literal: true

module BulkMsgSupport
  def db_name
    ActiveRecord::Base.connection.current_database
  end

  def self.import_bulk_msg_app
    # Setup the triggers, functions, etc
    config_dir = Rails.root.join('spec', 'fixtures', 'app_configs', 'config_files')
    config_fn = 'bulk-msg_test_config.yaml'
    SetupHelper.setup_app_from_import 'bulk-msg', config_dir, config_fn
  end

  def import_bulk_msg_app
    BulkMsgSupport.import_bulk_msg_app
  end

  def setup_bulk_message_app
    BulkMsgSupport.import_bulk_msg_app
    let_user_create :player_contacts
    let_user_create :dynamic_model__zeus_bulk_message_recipients
    let_user_create :dynamic_model__zeus_bulk_message_statuses
    let_user_create :dynamic_model__zeus_bulk_messages
    # ZeusBulkMessageRecipient#set_response temporarily switches the user's app_type
    # to bulk-msg (issue #1129) so that background-job updates pass the edit access check.
    # Grant the test user explicit create access in the bulk-msg app type as well so that
    # check_can_save passes when set_response runs under that app context.
    bulk_msg_app = Settings.bulk_msg_app
    if bulk_msg_app
      Admin::UserAccessControl.create! current_admin: @admin, app_type: bulk_msg_app,
                                       user: @user, access: :create, resource_type: :table,
                                       resource_name: :dynamic_model__zeus_bulk_message_recipients
    end
    @bulk_master = Master.find(-1)
    @bulk_master.current_user = @user
    @bulk_master.dynamic_model__zeus_bulk_message_recipients.update_all(response: nil)
  end

  def populate_recipients
    ms = []
    pcs = []
    recips = []
    7.times do
      ms << create_master
    end
    zbmsg = @bulk_master.dynamic_model__zeus_bulk_messages.create!(status: 'sent', name: 'test', channel: 'sms', message: 'message', send_date: DateTime.now, send_time: Time.now - 10.minutes)

    ms.each do |m|
      pc = m.player_contacts.create(data: "(123)123-1234 ext #{rand 100_000_000_000}", rank: 10, rec_type: :phone)
      pcs << pc
      recips << @bulk_master.dynamic_model__zeus_bulk_message_recipients.create!(record_type: pc.resource_name.singularize, record_id: pc.id, data: pc.data, rank: pc.rank, response: nil, zeus_bulk_message_id: zbmsg.id)
    end
  end
end
