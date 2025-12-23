# frozen_string_literal: true

require 'rails_helper'

describe 'admin dynamic model batch jobs link', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup

  before(:all) do
    SetupHelper.feature_setup
    make_an_admin
  end

  it 'shows batch jobs link when batch_trigger is configured' do
    # Close any extra windows and switch to main window
    windows.last.close while windows.length > 1
    switch_to_window(windows.first)

    # Create a dynamic model with batch_trigger configuration
    dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'Test Batch Trigger Model',
      table_name: 'test_version_tracking_recs',
      schema_name: 'dynamic_test',
      category: 'test',
      field_list: 'test_field',
      options: <<~YAML
        _configurations:
          batch_trigger:
            frequency: '1 hour'
            limit: 100

        default:
          label: Default
          fields:
            - test_field
        #{'  '}
          batch_trigger:
            on_record:
              update_this:
                one:
                  with:
                    test_field: 'batch updated'
      YAML
    )
    dm.current_admin = @admin
    dm.update_tracker_events

    admin_sign_in_with_2fa

    # Navigate to Dynamic Models admin page
    visit '/admin/dynamic_models'

    # Wait for the page to load
    expect(page).to have_css("#admin-item-#{dm.id}", wait: 10)

    # Find and click the Edit button for our dynamic model
    within "#admin-item-#{dm.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    # Wait for the edit form to load via AJAX
    expect(page).to have_css('.nav-tabs', wait: 10)

    # Should see the batch jobs label but no link since no job has been created
    within '#def-details-block' do
      expect(page).to have_css('label', text: 'batch jobs')

      # Link and job summary only appear when a job exists
      expect(page).not_to have_css('a.batch-jobs-link')
      expect(page).not_to have_css('.job-summary')
    end
  end

  it 'does not show batch jobs link when batch_trigger is not configured' do
    # Close any extra windows from previous tests and switch to main window
    windows.last.close while windows.length > 1
    switch_to_window(windows.first)

    # Log out if already signed in from previous test
    if page.has_css?('.admin-navbar', wait: 1)
      visit '/admins/sign_out'
      expect(page).to have_current_path('/admins/sign_in')
    end

    # Create a dynamic model without batch_trigger
    dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'Test No Batch Trigger',
      table_name: 'test_version_tracking_recs',
      schema_name: 'dynamic_test',
      category: 'test',
      field_list: 'test_field',
      options: <<~YAML
        default:
          label: Default
          fields:
            - test_field
      YAML
    )
    dm.current_admin = @admin
    dm.update_tracker_events

    admin_sign_in_with_2fa

    # Navigate to Dynamic Models admin page
    visit '/admin/dynamic_models'

    # Wait for the page to load
    expect(page).to have_css("#admin-item-#{dm.id}", wait: 10)

    # Find and click the Edit button for our dynamic model
    within "#admin-item-#{dm.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    # Wait for the edit form to load via AJAX
    expect(page).to have_css('.nav-tabs', wait: 10)

    # Should NOT see the batch jobs link
    within '#def-details-block' do
      expect(page).not_to have_css('label', text: 'batch jobs')
      expect(page).not_to have_css('a.batch-jobs-link')
    end
  end

  it 'filters background jobs by dynamic model GlobalID' do
    # Close any extra windows from previous tests and switch to main window
    windows.last.close while windows.length > 1
    switch_to_window(windows.first)

    # Log out if already signed in from previous test
    if page.has_css?('.admin-navbar', wait: 1)
      visit '/admins/sign_out'
      expect(page).to have_current_path('/admins/sign_in')
    end

    # Enable delayed job creation but prevent execution
    # This allows RecurringBatchTask.schedule_task to create job records
    Delayed::Worker.delay_jobs = true

    # Create a dynamic model with batch_trigger
    # The after_save :handle_batch_schedule callback should automatically create a RecurringBatchTask
    dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'Test Batch Jobs Filtering',
      table_name: 'test_version_tracking_recs',
      schema_name: 'dynamic_test',
      category: 'test',
      field_list: 'test_field',
      options: <<~YAML
        _configurations:
          batch_trigger:
            frequency: '30 minutes'

        default:
          label: Default
          fields:
            - test_field
        #{'  '}
          batch_trigger:
            on_record:
              update_this:
                one:
                  with:
                    test_field: 'processed'
      YAML
    )
    dm.current_admin = @admin
    dm.update_tracker_events

    # Create another dynamic model with different batch trigger to verify filtering
    dm2 = DynamicModel.create!(
      current_admin: @admin,
      name: 'Test Other Batch Model',
      table_name: 'test_version_tracking_recs',
      schema_name: 'dynamic_test',
      category: 'test',
      field_list: 'test_field',
      options: <<~YAML
        _configurations:
          batch_trigger:
            frequency: '1 hour'

        default:
          label: Default
          fields:
            - test_field
      YAML
    )
    dm2.current_admin = @admin
    dm2.update_tracker_events

    # Restore original delayed job setting
    Delayed::Worker.delay_jobs = false

    # Get the GlobalIDs for both models
    gid1 = dm.to_global_id.to_s
    gid2 = dm2.to_global_id.to_s

    # Find the RecurringBatchTask jobs that should have been created automatically
    job1 = Delayed::Job.where('handler LIKE ?', "%#{gid1}%").first
    job2 = Delayed::Job.where('handler LIKE ?', "%#{gid2}%").first

    expect(job1).to be_present, "Expected RecurringBatchTask to be created for dm with GID #{gid1}"
    expect(job2).to be_present, "Expected RecurringBatchTask to be created for dm2 with GID #{gid2}"
    expect(job1.id).not_to eq(job2.id)

    admin_sign_in_with_2fa

    # Navigate to Dynamic Models admin page
    visit '/admin/dynamic_models'

    # Wait for the page to load
    expect(page).to have_css("#admin-item-#{dm.id}", wait: 10)

    # Find and click the Edit button for the first dynamic model
    within "#admin-item-#{dm.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    # Wait for the edit form to load via AJAX
    expect(page).to have_css('.nav-tabs', wait: 10)

    # Click the batch jobs link from the Details tab
    within '#def-details-block' do
      expect(page).to have_css('a.batch-jobs-link', text: 'view job')
      batch_jobs_link = find('a.batch-jobs-link')

      # Verify the link has the correct filter parameters
      expect(batch_jobs_link[:href]).to include('filter%5Bqueue%5D=batch')
      expect(batch_jobs_link[:href]).to include("search_attrs%5Bhandler%5D=#{CGI.escape(gid1)}")

      # Should see job summary with formatted dates
      expect(page).to have_css('.job-summary')
      within '.job-summary' do
        expect(page).to have_content('next run:')
        expect(page).to have_css('span[data-format-datetime-local="true"]')
        expect(page).to have_content('status:')
        expect(page).to have_content('Active')
        expect(page).to have_content('last updated:')
      end

      # Click the link (opens in new tab with target="_blank")
      batch_jobs_link.click
    end

    # Switch to the new window that was opened
    new_window = windows.last
    within_window(new_window) do
      # Wait for the job reviews page to load
      expect(page).to have_css('table', wait: 10)

      # Should see job for first dynamic model
      expect(page).to have_css('table tr', text: job1.id.to_s)
      # Should NOT see job for second dynamic model (check within table rows only)
      expect(page).not_to have_css('table tbody tr', text: /\A\s*#{Regexp.escape(job2.id.to_s)}\s/)
    end

    # Now test the second dynamic model
    # Close extra windows and switch back to main window
    windows.last.close while windows.length > 1
    switch_to_window(windows.first)

    visit '/admin/dynamic_models'

    # Wait for the dynamic models page to load
    expect(page).to have_css("#admin-item-#{dm2.id}", wait: 10)

    within "#admin-item-#{dm2.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    # Wait for the modal/form and tabs to load
    expect(page).to have_css('.nav-tabs', wait: 10)
    expect(page).to have_css('#def-details-block', wait: 10)

    within '#def-details-block' do
      expect(page).to have_css('a.batch-jobs-link', text: 'view job', wait: 10)
      batch_jobs_link2 = find('a.batch-jobs-link')

      # Verify the link has the correct filter parameters
      expect(batch_jobs_link2[:href]).to include('filter%5Bqueue%5D=batch')
      expect(batch_jobs_link2[:href]).to include("search_attrs%5Bhandler%5D=#{CGI.escape(gid2)}")

      # Click the link
      batch_jobs_link2.click
    end

    # Switch to the new window that was opened
    new_window = windows.last
    within_window(new_window) do
      # Wait for the job reviews page to load
      expect(page).to have_css('table', wait: 10)

      # Should see job for second dynamic model
      expect(page).to have_css('table tr', text: job2.id.to_s)
      # Should NOT see job for first dynamic model (check within table rows only)
      expect(page).not_to have_css('table tbody tr', text: /\A\s*#{Regexp.escape(job1.id.to_s)}\s/)
    end
  ensure
    # Always restore the original delay_jobs setting
    Delayed::Worker.delay_jobs = false
  end
end
