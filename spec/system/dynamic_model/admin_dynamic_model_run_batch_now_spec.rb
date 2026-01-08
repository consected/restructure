# frozen_string_literal: true

require 'rails_helper'

describe 'admin dynamic model run batch now button', js: true, driver: $browser_driver do
  include ModelSupport
  include MasterSupport
  include AdminActionsSetup

  before(:all) do
    SetupHelper.feature_setup
    make_an_admin

    # Get or create app_type first
    @app_type = Admin::AppType.active.first

    # Create or find batch user for testing
    @batch_user = User.find_or_create_by!(email: 'batch_test_user@test.com') do |user|
      user.first_name = 'Batch'
      user.last_name = 'User'
      user.current_admin = @admin
      user.app_type = @app_type
      user.disabled = false
    end
    # Ensure app_type is set for existing users
    @batch_user.update!(app_type: @app_type) unless @batch_user.app_type
  end

  def cleanup_browser_state
    # Close any extra windows and switch to main window
    windows.last.close while windows.length > 1
    switch_to_window(windows.first)

    # Close any open modals via JavaScript
    begin
      page.execute_script("$('.modal').modal('hide')")
    rescue StandardError
      nil
    end
    sleep 0.3

    # Log out if already signed in from previous test
    return unless page.has_css?('.admin-navbar', wait: 1)

    visit '/admins/sign_out'
    expect(page).to have_current_path('/admins/sign_in')
  end

  it 'shows and executes run batch now button when batch_trigger is configured' do
    cleanup_browser_state

    # Create a dynamic model with batch_trigger configuration
    dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'Test Run Batch Now Model',
      table_name: 'test_version_tracking_recs',
      schema_name: 'dynamic_test',
      category: 'test',
      field_list: 'test_field',
      options: <<~YAML
        _configurations:
          batch_trigger:
            frequency: '1 hour'
            limit: 5
            user: batch_test_user@test.com

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
                    test_field: 'batch processed'
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

    # Should see the batch jobs section with the run batch now button
    within '#def-details-block' do
      expect(page).to have_css('label', text: 'batch jobs')
      expect(page).to have_css('a.show-in-modal', text: 'Run Batch Now', wait: 5)

      # Click the Run Batch Now button to open the confirmation dialog
      find('a.show-in-modal', text: 'Run Batch Now').click
    end

    # Wait for modal to appear
    expect(page).to have_css('.modal', visible: true, wait: 5)

    # Verify confirmation message
    within '.modal' do
      expect(page).to have_content('This will run immediately on the server')
      expect(page).to have_content('Click Run if you are sure')

      # Click the Run button to execute batch processing
      click_link 'Run'
    end

    # Wait for AJAX to complete and check for result in container
    expect(page).to have_css('.dynamic-model--run-batch-result', wait: 10)

    # Verify success message appears in the result container
    within '.dynamic-model--run-batch-result-container' do
      expect(page).to have_content('Batch processing completed', wait: 10)
    end
  end

  it 'handles errors gracefully when batch processing fails' do
    cleanup_browser_state

    # Create a dynamic model with batch_trigger but specify an invalid user email
    # This will cause the batch processing to fail when trying to find the user
    dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'Test Error Handling Model',
      table_name: 'test_version_tracking_recs',
      schema_name: 'dynamic_test',
      category: 'test',
      field_list: 'test_field',
      options: <<~YAML
        _configurations:
          batch_trigger:
            frequency: '1 hour'
            limit: 5
            user: nonexistent_user_that_does_not_exist@invalid.test

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
                    test_field: 'updated'
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

    # Should see the batch jobs section
    within '#def-details-block' do
      expect(page).to have_css('a.show-in-modal', text: 'Run Batch Now', wait: 5)

      # Click the Run Batch Now button to open dialog
      find('a.show-in-modal', text: 'Run Batch Now').click
    end

    # Wait for modal and click Run
    expect(page).to have_css('.modal', visible: true, wait: 5)
    within '.modal' do
      click_link 'Run'
    end

    # Wait for result and verify error message
    expect(page).to have_css('.dynamic-model--run-batch-result', wait: 10)
    within '.dynamic-model--run-batch-result-container' do
      expect(page).to have_content('Batch processing failed', wait: 10)
    end
  end

  it 'does not show run batch now button when batch_trigger is not configured' do
    cleanup_browser_state

    # Create a dynamic model without batch_trigger
    dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'Test No Batch Button',
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

    # Should NOT see the batch jobs section or run batch now button
    within '#def-details-block' do
      expect(page).not_to have_css('label', text: 'batch jobs')
      expect(page).not_to have_css('a.show-in-modal', text: 'Run Batch Now')
    end
  end

  it 'allows multiple consecutive runs of batch processing' do
    cleanup_browser_state

    # Create a dynamic model with batch_trigger (will process 0 records but should allow multiple clicks)
    dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'Test Multiple Runs Model',
      table_name: 'test_version_tracking_recs',
      schema_name: 'dynamic_test',
      category: 'test',
      field_list: 'test_field',
      options: <<~YAML
        _configurations:
          batch_trigger:
            frequency: '1 hour'
            limit: 2
            user: batch_test_user@test.com

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

    admin_sign_in_with_2fa

    # First run
    visit '/admin/dynamic_models'
    expect(page).to have_css("#admin-item-#{dm.id}", wait: 10)

    within "#admin-item-#{dm.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    expect(page).to have_css('.nav-tabs', wait: 10)
    expect(page).to have_css('#def-details-block', wait: 5)

    within '#def-details-block' do
      expect(page).to have_css('a.show-in-modal', text: 'Run Batch Now', wait: 5)
      find('a.show-in-modal', text: 'Run Batch Now').click
    end

    expect(page).to have_css('.modal', visible: true, wait: 5)
    within '.modal' do
      click_link 'Run'
    end

    expect(page).to have_css('.dynamic-model--run-batch-result', wait: 10)
    within '.dynamic-model--run-batch-result-container' do
      expect(page).to have_content('Batch processing completed', wait: 5)
    end

    # Close the modal
    page.execute_script("$('.modal').modal('hide')")
    expect(page).not_to have_css('.modal.show', visible: true, wait: 5)
    sleep 0.5

    # Second run - refresh the page to get a clean state, simulating real user behavior
    # This also verifies the button works after page reload
    visit '/admin/dynamic_models'
    expect(page).to have_css("#admin-item-#{dm.id}", wait: 10)

    within "#admin-item-#{dm.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    expect(page).to have_css('.nav-tabs', wait: 10)
    expect(page).to have_css('#def-details-block', wait: 5)

    within '#def-details-block' do
      expect(page).to have_css('a.show-in-modal', text: 'Run Batch Now', wait: 5)
      find('a.show-in-modal', text: 'Run Batch Now').click
    end

    expect(page).to have_css('.modal', visible: true, wait: 5)
    within '.modal' do
      click_link 'Run'
    end

    # Wait for second result
    expect(page).to have_css('.dynamic-model--run-batch-result', wait: 10)
    within '.dynamic-model--run-batch-result-container' do
      expect(page).to have_content('Batch processing completed', wait: 5)
    end
  end
end
