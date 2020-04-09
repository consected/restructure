# frozen_string_literal: true

module BulkMsgSupport
  def db_name
    "fpa_test#{ENV['TEST_ENV_NUMBER']}"
  end

  def self.import_bulk_msg_app
    # Setup the triggers, functions, etc
    config_dir = Rails.root.join('db', 'app_configs')
    config_fn = 'bulk-msg_config.yaml'
    SetupHelper.setup_app_from_import 'bulk-msg', config_dir, config_fn
  end

  def import_bulk_msg_app
    BulkMsgSupport.import_bulk_msg_app
  end
end
