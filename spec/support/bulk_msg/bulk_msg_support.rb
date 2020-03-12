# frozen_string_literal: true

module BulkMsgSupport
  def db_name
    "fpa_test#{ENV['TEST_ENV_NUMBER']}"
  end

  def self.import_bulk_msg_app
    # Setup the triggers, functions, etc
    sql_files = %w[bulk/create_zeus_bulk_messages_table.sql bulk/dup_check_recipients.sql bulk/create_zeus_bulk_message_recipients_table.sql bulk/create_al_bulk_messages.sql bulk/create_zeus_bulk_message_statuses.sql bulk/setup_master.sql bulk/create_zeus_short_links.sql bulk/create_player_contact_phone_infos.sql bulk/create_zeus_short_link_clicks.sql 0-scripts/z_grant_roles.sql]
    sql_source_dir = Rails.root.join('db', 'app_specific', 'bulk-msg', 'aws-db')
    config_dir = Rails.root.join('db', 'app_configs')
    config_fn = 'bulk-msg_config.yaml'
    SetupHelper.setup_app_from_import 'bulk-msg', sql_source_dir, sql_files, config_dir, config_fn
  end

  def import_bulk_msg_app
    BulkMsgSupport.import_bulk_msg_app
  end
end
