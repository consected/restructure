# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Import app configuration with batch_trigger frequency once', type: :model do
  include ModelSupport

  before :each do
    Seeds.setup
    create_admin
    SetupHelper.setup_al_player_contact_phones

    # Clean up any existing test app
    @app_name = 'test_batch_once'
    existing_app = Admin::AppType.where(name: @app_name).first
    if existing_app
      existing_app.disabled = true
      existing_app.current_admin = @admin
      existing_app.save!
    end

    # Create test app type
    @app_type = Admin::AppType.create!(name: @app_name, label: 'Test Batch Once', current_admin: @admin)

    # Create a batch user for the config
    @batch_user = User.find_or_create_by!(email: 'batch_test@example.com') do |user|
      user.first_name = 'Batch'
      user.last_name = 'Test'
      user.current_admin = @admin
      user.app_type = @app_type
      user.disabled = false
    end

    # Create a dynamic model with batch_trigger frequency: once
    # Use existing test table that's available
    @dm = DynamicModel.create!(
      name: 'test_batch_once_model',
      table_name: 'test_version_tracking_recs',
      schema_name: 'dynamic_test',
      category: 'test',
      field_list: 'test_field',
      current_admin: @admin,
      options: <<~YAML
        _configurations:
          batch_trigger:
            frequency: 'once'
            label: test once batch
            user: batch_test@example.com

        default:
          label: Default
          fields:
            - test_field
          batch_trigger:
            on_record:
              update_this:
                one:
                  with:
                    test_field: processed
      YAML
    )
    @dm.current_admin = @admin
    @dm.update_tracker_events
    @dm.save!

    # Save the ID for later lookup
    @dm_id = @dm.id
  end

  after :each do
    # Clean up any jobs that may have been created
    @dm = DynamicModel.find_by(id: @dm_id) if @dm_id
    RecurringBatchTask.unschedule_task @dm if @dm
  end

  it 'does not create batch trigger job when importing app with frequency: once' do
    # Export the app configuration
    config_hash = @app_type.export_config

    # Count jobs before import
    jobs_before = Delayed::Job.count

    # Import the configuration (simulating a re-import scenario)
    res, results = Admin::AppTypeImport.import_config(config_hash, @admin, name: @app_name, force_update: :force)

    # Check if there was an error
    if results.is_a?(Exception)
      puts "Import failed with error: #{results.message}"
      puts results.backtrace.first(10).join("\n")
      raise results
    end

    expect(res).to be_a(Admin::AppType)
    expect(results).to be_a(Hash)
    expect(results.dig('failures')).to be_nil

    # Reload the dynamic model
    @dm = DynamicModel.find(@dm_id)

    # Verify that NO new job was created during import
    jobs_after = Delayed::Job.count
    expect(jobs_after).to eq(jobs_before), "Expected no new jobs to be created during import with frequency: once, but job count changed from #{jobs_before} to #{jobs_after}"

    # Verify task_schedule is nil (no job scheduled)
    expect(@dm.task_schedule).to be_nil, 'Expected no batch trigger job to be scheduled after import with frequency: once'
    
    puts "✓ Import successful - no 'once' frequency jobs created during import"
    puts "  This resolves GitHub issue #225: batch trigger dynamic models set to 'once' are no longer"
    puts "  triggered unexpectedly when included in an app_type import."
  end

  it 'verifies import_in_progress flag is managed correctly' do
    # This test ensures the AppTypeImport.import_in_progress? method works correctly

    # Before import, flag should be false
    expect(Admin::AppTypeImport.import_in_progress?).to be false

    # After import completes, flag should be false again
    config_hash = @app_type.export_config
    Admin::AppTypeImport.import_config(config_hash, @admin, name: @app_name, force_update: :force)

    expect(Admin::AppTypeImport.import_in_progress?).to be false
  end
end
