# frozen_string_literal: true

module BulkMsgSupport
  def db_name
<<<<<<< HEAD
<<<<<<< HEAD
    ActiveRecord::Base.connection.current_database
=======
    "fpa_test#{ENV['TEST_ENV_NUMBER']}"
>>>>>>> 65d7808... Baseline code
=======
    ActiveRecord::Base.connection.current_database
>>>>>>> ba15603... Get db name automatically
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
