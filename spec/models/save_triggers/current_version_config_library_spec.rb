# frozen_string_literal: true

require 'rails_helper'

# Reproduces issue #1409: an existing dynamic model record can continue using
# the previous config-library version after use_current_version is enabled.
RSpec.describe 'Issue #1409 - current-version config library in save triggers', type: :model do
  include MasterSupport
  include ModelSupport

  before :all do
    @original_allow_migrations = Settings::AllowDynamicMigrations
    change_setting('AllowDynamicMigrations', true)

    create_admin
    create_user

    @table_name = 'test_issue_repro_save_trigger_recs'
    @resource_name = "dynamic_model__#{@table_name}"
    @library_category = "issue_1409_category_#{SecureRandom.hex(4)}"
    @library_name = "issue_1409_library_#{SecureRandom.hex(4)}"

    DynamicModel.active.where(table_name: @table_name).each { |definition| definition.disable!(@admin) }
    if DynamicModel.const_defined?(:TestIssue1409SaveTriggerRec, false)
      DynamicModel.send(:remove_const, :TestIssue1409SaveTriggerRec)
    end

    @config_library = Admin::ConfigLibrary.create!(
      current_admin: @admin,
      name: @library_name,
      category: @library_category,
      format: 'yaml',
      options: <<~YAML
        _definitions_lib:
          save_message: &save_message 'test 1'
      YAML
    )

    @dynamic_model = DynamicModel.create!(
      current_admin: @admin,
      name: 'Test Current Version Save Trigger Recs',
      table_name: @table_name,
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test,
      field_list: 'value',
      options: <<~YAML
        # @library #{@library_category} #{@library_name}
        _configurations:
          use_current_version: true
        default:
          fields:
            - value
          save_trigger:
            on_save:
              log:
                severity: warn
                message: *save_message
      YAML
    )
    @dynamic_model.update_tracker_events
    setup_access @resource_name, resource_type: :table, access: :create, user: @user
  end

  after :all do
    @dynamic_model&.disable!(@admin)
    change_setting('AllowDynamicMigrations', @original_allow_migrations)
  end

  it 'uses the current config-library version when an existing record is saved' do
    master = Master.create!(current_user: @user)
    master.current_user = @user
    logged_messages = []
    allow(Rails.logger).to receive(:warn) { |message| logged_messages << message }

    record = master.public_send(@resource_name).create!(current_user: @user, value: 'v1')
    expect(logged_messages).to include(a_string_including('test 1'))
    logged_messages.clear

    @config_library.current_admin = @admin
    @config_library.update!(options: <<~YAML)
      _definitions_lib:
        save_message: &save_message 'test 2'
    YAML

    record.update!(value: 'v2')

    expect(logged_messages).to include(a_string_including('test 2'))
  end
end
