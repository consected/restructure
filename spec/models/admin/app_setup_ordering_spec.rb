# frozen_string_literal: true

# Verify app dependencies are ready before importing configurations that depend on them.
require 'rails_helper'

RSpec.describe 'App setup migration ordering', type: :model do
  describe PlayIpaSetup do
    it 'creates the Biodata participant table without changing the app search path' do
      connection = ActiveRecord::Base.connection
      original_search_path = connection.schema_search_path

      described_class.migrate_biodata_participant_dependency

      expect(connection.data_source_exists?('biodata.biodata_participants')).to be(true)
      expect(connection.schema_search_path).to eq(original_search_path)
    end

    it 'makes the Biodata participant table available before importing PLAY-IPA' do
      admin = instance_double(Admin)
      allow(UserSupport).to receive(:create_admin).and_return([admin])
      allow(SetupHelper).to receive(:cleanup_migrations)
      allow(described_class).to receive(:direct_schema_setup)
      allow(described_class).to receive(:direct_db_setup)
      allow(described_class).to receive(:fix_is_blank_anchor)
      allow(described_class).to receive(:regenerate_activity_log_table)
      allow(described_class).to receive(:fix_activity_log_history_tables)
      allow(DynamicModel).to receive(:routes_reload)
      allow(Rails.application.routes_reloader).to receive(:reload!)
      allow(ActivityLog).to receive(:enable_active_configurations)

      expect(described_class).to receive(:migrate_biodata_participant_dependency).ordered
      expect(described_class).to receive(:import_app_type_config).with(admin:).ordered

      described_class.setup_play_ipa_database
    end
  end

  describe PlayIpaSetup do
    it 'resumes Biodata definitions before resuming PLAY-IPA definitions' do
      allow(SetupHelper).to receive(:spec_tally_names).and_return([])
      allow(SetupHelper).to receive(:spec_tally_done?).with('play_ipa_database').and_return(true)
      allow(described_class).to receive(:ensure_play_ipa_activity_logs_enabled)

      expect(SetupHelper).to receive(:resume_app_definitions).with('biodata').ordered
      expect(SetupHelper).to receive(:resume_app_definitions).with('play_ipa', 'sample_tracking').ordered

      described_class.set_up_play_ipa
    end
  end

  describe StudyInfoSetup do
    it 'creates the user map model and table before its dependent save-trigger config' do
      admin, = UserSupport.create_admin(nil, with_matching_user: true)
      change_setting('AllowDynamicMigrations', true)
      described_class.ensure_user_map_names_table

      described_class.import_user_map_names(admin:)

      expect(DynamicModel.active.exists?(schema_name: 'ml_app', table_name: 'user_map_names')).to be(true)
      expect(ActiveRecord::Base.connection.data_source_exists?('ml_app.user_map_names')).to be(true)
    ensure
      change_setting('AllowDynamicMigrations', nil)
    end

    it 'imports only the user map tables as the Study Info prerequisites' do
      admin = instance_double(Admin)
      config_file = Rails.root.join('db', 'app_configs', StudyInfoMain::AppImportFile)
      allow(described_class).to receive(:find_config_file).and_return(config_file)
      allow(ActiveRecord::Base.connection).to receive(:data_source_exists?).with(/ml_app\.user_/).and_return(true)
      allow(DynamicModel).to receive(:active).and_return(
        double(exists?: true)
      )
      expected_app_type = Admin::AppType.new

      expect(Admin::AppTypeImport).to receive(:import_config) do |config, passed_admin, **options|
        expect(passed_admin).to eq(admin)
        expect(config.dig('app_type', 'associated_dynamic_models').map { |model| model['table_name'] })
          .to eq(%w[user_map_names user_current_signins])
        expect(options).to include(format: :raw, force_update: :changed, skip_fail: false)
        [expected_app_type, {}]
      end

      described_class.import_user_map_names(admin:)
    end

    it 'makes the user map table available before importing Study Info' do
      admin = instance_double(Admin)
      allow(UserSupport).to receive(:create_admin).and_return([admin])
      allow(SetupHelper).to receive(:cleanup_migrations)
      allow(described_class).to receive(:direct_schema_setup)
      allow(DynamicModel).to receive(:routes_reload)
      allow(Rails.application.routes_reloader).to receive(:reload!)
      allow(ActivityLog).to receive(:enable_active_configurations)

      expect(described_class).to receive(:ensure_user_map_names_table).ordered
      expect(described_class).to receive(:import_user_map_names).with(admin:).ordered
      expect(described_class).to receive(:import_app_type_config).with(admin:).ordered

      described_class.setup_study_info_database
    end
  end
end
