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

    # Create batch user for testing using the standard support method so it gets
    # a proper password, confirmed_at, and app_type UAC — making it findable by
    # User.active.find_by_email via user_for_conf_snippet
    @batch_user = User.find_by(email: 'batch_test_user@test.com')
    if @batch_user
      @batch_user.current_admin = @admin
      @batch_user.update!(disabled: false, app_type: @app_type)
    else
      # Save admin-level variables before create_user overwrites them
      # (create_user sets @good_email, @good_password, @user to the new user)
      saved_good_email = @good_email
      saved_good_password = @good_password
      saved_user = @user

      create_user(nil, '', email: 'batch_test_user@test.com', app_type: @app_type)
      @batch_user = User.find_by(email: 'batch_test_user@test.com')

      # Restore admin login variables so admin_sign_in_with_2fa works correctly
      @good_email = saved_good_email
      @good_password = saved_good_password
      @user = saved_user
    end
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

  it 'run batch now button works after saving the dynamic model definition' do
    cleanup_browser_state

    # Create a dynamic model with batch_trigger configuration
    dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'Test Button After Save',
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
    expect(page).to have_css("#admin-item-#{dm.id}", wait: 10)

    # Click Edit to open the edit form
    within "#admin-item-#{dm.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    # Wait for the edit form to load
    expect(page).to have_css('.nav-tabs', wait: 10)
    expect(page).to have_css('#def-details-block', wait: 5)

    # Verify Run Batch Now button is present before save
    within '#def-details-block' do
      expect(page).to have_css('a.show-in-modal', text: 'Run Batch Now', wait: 5)
    end

    # Save the dynamic model by clicking submit button in the admin form
    # The form is in the admin-edit-form block, which is above the tabs
    within '.admin-edit-form' do
      # Scroll to and click the save button
      save_button = find('input[type="submit"][value="save"]', match: :first)
      page.execute_script('arguments[0].scrollIntoView(true);', save_button)
      sleep 0.3
      save_button.click
    end

    # Wait for the form to reload after saving
    # The admin edit form shows success via re-rendering the updated item
    expect(page).to have_css('.admin-edit-form', wait: 10)

    # Click Edit again to reopen the form with fresh content
    within "#admin-item-#{dm.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    # Wait for the edit form to reload
    expect(page).to have_css('.nav-tabs', wait: 10)
    expect(page).to have_css('#def-details-block', wait: 5)

    # Verify the Run Batch Now button still works after the AJAX update
    within '#def-details-block' do
      expect(page).to have_css('label', text: 'batch jobs', wait: 5)
      expect(page).to have_css('a.show-in-modal', text: 'Run Batch Now', wait: 5)

      # Click the Run Batch Now button to open the confirmation dialog
      find('a.show-in-modal', text: 'Run Batch Now').click
    end

    # Wait for modal to appear - this is the key test!
    # Previously this would fail because the event handler was lost after AJAX update
    expect(page).to have_css('.modal', visible: true, wait: 5)

    # Verify confirmation message appears
    within '.modal' do
      expect(page).to have_content('This will run immediately on the server')
      expect(page).to have_content('Click Run if you are sure')

      # Click the Run button to execute batch processing
      click_link 'Run'
    end

    # Wait for result and verify success
    expect(page).to have_css('.dynamic-model--run-batch-result', wait: 10)
    within '.dynamic-model--run-batch-result-container' do
      expect(page).to have_content('Batch processing completed', wait: 10)
    end
  end
end
