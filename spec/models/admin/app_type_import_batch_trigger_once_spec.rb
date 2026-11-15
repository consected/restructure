# frozen_string_literal: true

require 'rails_helper'

# Tests for GitHub issue #225: Batch trigger dynamic models set to "once" should not be
# triggered during app_type import, only when explicitly saved outside of import context.
#
# This test suite verifies that:
# 1. Dynamic models with batch_trigger frequency: 'once' do NOT create jobs during app type import
# 2. The Admin::AppTypeImport.import_in_progress? flag is properly managed before/after import
# 3. Jobs ARE created when saving the dynamic model after import completes (normal behavior restored)
#
# The fix prevents one-time batch jobs from being recreated on every app configuration re-import,
# while ensuring they can still be created when the model is explicitly saved by an admin.
RSpec.describe 'Import app configuration with batch_trigger frequency once', type: :model do
  include ModelSupport

  before :all do
    # Enable delayed job creation for testing
    @original_delay_jobs = Delayed::Worker.delay_jobs
    Delayed::Worker.delay_jobs = true

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

    # Create test app type (must not be disabled to be active)
    @app_type = Admin::AppType.create!(name: @app_name, label: 'Test Batch Once', disabled: false, current_admin: @admin)

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

    # Associate the dynamic model with the app type through user access control
    # This makes it an "active" model configuration
    Admin::UserAccessControl.create!(
      user: @batch_user,
      resource_type: :table,
      resource_name: 'dynamic_model__test_version_tracking_recs',
      access: :read,
      app_type: @app_type,
      current_admin: @admin
    )

    # Reset active model configurations cache
    DynamicModel.reset_active_model_configurations!

    # Save the ID for later lookup
    @dm_id = @dm.id

    # Verify the dynamic model is properly configured and active
    expect(@dm.active_model_configuration?).to be(true), 'Dynamic model should be active after adding user access control'
  end

  after :all do
    # Clean up any jobs that may have been created
    @dm = DynamicModel.find_by(id: @dm_id) if @dm_id
    RecurringBatchTask.unschedule_task @dm if @dm

    # Restore original delayed job setting
    Delayed::Worker.delay_jobs = @original_delay_jobs
  end

  it 'does not create batch trigger job when importing app with frequency: once' do
    # First, verify a job WAS created when we initially saved the dynamic model
    # (this proves our test setup is correct and jobs can be created)
    initial_job = Delayed::Job.where('handler LIKE ?', "%#{@dm.to_global_id}%").first
    expect(initial_job).to be_present, 'Expected initial RecurringBatchTask to be created when dynamic model was saved'
    initial_job_count = Delayed::Job.count

    # Clean up the initial job so we can test import behavior
    RecurringBatchTask.unschedule_task @dm
    @dm.reload
    expect(@dm.task_schedule).to be_nil, 'Job should be cleared before import test'

    # Export the app configuration
    config_hash = @app_type.export_config

    # Count jobs before import (should be less than initial since we cleaned up)
    jobs_before = Delayed::Job.count
    expect(jobs_before).to be < initial_job_count, 'Job count should be lower after cleanup'

    # Import the configuration (simulating a re-import scenario)
    # During import, import_in_progress? will be true, so no job should be created
    res, results = Admin::AppTypeImport.import_config(config_hash, @admin, name: @app_name, force_update: :force)

    # Check if there was an error
    if results.is_a?(Exception)
      puts "Import failed with error: #{results.message}"
      puts results.backtrace.first(10).join("\n")
      raise results
    end

    expect(res).to be_a(Admin::AppType)
    expect(results).to be_a(Hash)
    expect(results['failures']).to be_nil

    # Reload the dynamic model
    @dm = DynamicModel.find(@dm_id)

    # Verify that NO new job was created during import
    jobs_after = Delayed::Job.count
    expect(jobs_after).to eq(jobs_before), "Expected no new jobs to be created during import with frequency: once, but job count changed from #{jobs_before} to #{jobs_after}"

    # Verify task_schedule is still nil (no job scheduled during import)
    expect(@dm.task_schedule).to be_nil, 'Expected no batch trigger job to be scheduled during import with frequency: once'

    # Now test that saving AFTER import DOES create a job (proving the fix only affects import)
    @dm.current_admin = @admin
    @dm.save!
    @dm.reload

    # Verify a job WAS created after import completes (normal behavior restored)
    post_import_job = Delayed::Job.where('handler LIKE ?', "%#{@dm.to_global_id}%").first
    expect(post_import_job).to be_present, 'Expected RecurringBatchTask to be created when saving after import completes'
    expect(@dm.task_schedule).to be_present, 'Expected task_schedule to be set after import completes'
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

  it 'creates batch trigger job when saving dynamic model after import completes' do
    # Verify the dynamic model is active before test
    expect(@dm.active_model_configuration?).to be(true)

    # Clean up any existing job from initial setup
    RecurringBatchTask.unschedule_task @dm
    @dm.reload
    expect(@dm.task_schedule).to be_nil, 'Job should be cleared before test'

    # Count jobs before import (should be 0 after cleanup)
    jobs_before_import = Delayed::Job.count

    # Import the configuration
    config_hash = @app_type.export_config
    Admin::AppTypeImport.import_config(config_hash, @admin, name: @app_name, force_update: :force)
    jobs_after_import = Delayed::Job.count

    # Verify NO job created during import
    expect(jobs_after_import).to eq(jobs_before_import),
                                 "Expected no jobs during import, but count changed from #{jobs_before_import} to #{jobs_after_import}"

    # Reload the dynamic model
    @dm = DynamicModel.find(@dm_id)

    # Verify still active after reload (user access controls should persist through import)
    expect(@dm.active_model_configuration?).to be(true),
                                               'Dynamic model should still be active after import'

    # Now save the dynamic model AFTER import completes
    # This should trigger batch job creation since import_in_progress? is now false
    @dm.current_admin = @admin
    @dm.save!
    @dm.reload

    # Verify a job WAS created after saving post-import
    jobs_after_save = Delayed::Job.count
    expect(jobs_after_save).to eq(jobs_before_import + 1),
                               "Expected 1 job to be created after saving post-import, but job count is #{jobs_after_save} (started with #{jobs_before_import})"

    # Verify task_schedule exists
    expect(@dm.task_schedule).not_to be_nil,
                                     'Expected batch trigger job to be scheduled after saving post-import'
  end

  # Tests for GitHub issue #1090: Allow admin to specify run_at time for frequency: 'once' batch triggers.
  #
  # handle_batch_schedule currently hardcodes run_at: DateTime.now + 10.seconds for the 'once' branch,
  # ignoring any run_at value present in _configurations.batch_trigger. The fix should read run_at
  # from config (when present) and only fall back to DateTime.now + 10.seconds when it is absent.
  describe 'run_at configuration for frequency once - issue #1090' do
    it 'schedules the batch trigger job at the configured run_at time when frequency is once and run_at is specified' do
      # Given: a future datetime specified explicitly in the batch_trigger configuration
      specified_time = 2.hours.from_now.change(usec: 0)
      run_at_string = specified_time.strftime('%Y-%m-%d %H:%M:%S')

      dm = DynamicModel.find(@dm_id)
      dm.options = <<~YAML
        _configurations:
          batch_trigger:
            frequency: 'once'
            run_at: '#{run_at_string}'
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

      # When: the dynamic model is saved, capture the run_at argument passed to schedule_task
      captured_run_at = nil
      allow(RecurringBatchTask).to receive(:schedule_task) do |_owner, _data, **kwargs|
        captured_run_at = kwargs[:run_at]
      end

      dm.current_admin = @admin
      dm.save!

      # Then: schedule_task must have been called with the configured time, NOT DateTime.now + 10s
      # This test FAILS until the fix is applied because the current implementation always passes
      # DateTime.now + 10.seconds and ignores the configured run_at value.
      expect(captured_run_at).not_to be_nil,
                                     'Expected RecurringBatchTask.schedule_task to have been called with a run_at argument'
      # Compare as unix timestamps to avoid DateTime vs TimeWithZone type errors
      expect(captured_run_at.to_time.to_i).to be_within(60).of(specified_time.to_i),
                                             "Expected run_at to be near #{specified_time} (from config), " \
                                             "but got #{captured_run_at} — the implementation is ignoring the configured run_at"
    end

    it 'schedules the batch trigger job approximately 10 seconds from now when frequency is once and run_at is not specified' do
      # Given: a batch_trigger with frequency: once but NO run_at configured (existing default behaviour)
      dm = DynamicModel.find(@dm_id)
      dm.options = <<~YAML
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

      # When: the dynamic model is saved, capture the run_at argument passed to schedule_task
      captured_run_at = nil
      before_save = DateTime.now
      allow(RecurringBatchTask).to receive(:schedule_task) do |_owner, _data, **kwargs|
        captured_run_at = kwargs[:run_at]
      end

      dm.current_admin = @admin
      dm.save!

      # Then: schedule_task must have been called with approximately DateTime.now + 10 seconds
      # This preserves the existing default behaviour when no run_at is configured.
      expect(captured_run_at).not_to be_nil,
                                     'Expected RecurringBatchTask.schedule_task to have been called with a run_at argument'
      # Compare as unix timestamps to avoid DateTime vs TimeWithZone type errors
      expect(captured_run_at.to_time.to_i).to be_within(5).of((before_save + 10.seconds).to_time.to_i),
                                             "Expected run_at to be approximately #{before_save + 10.seconds} " \
                                             "(DateTime.now + 10s), but got #{captured_run_at}"
    end
  end
end
