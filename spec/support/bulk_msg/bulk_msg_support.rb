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
end
