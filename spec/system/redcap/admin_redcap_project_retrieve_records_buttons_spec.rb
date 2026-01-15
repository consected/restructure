# frozen_string_literal: true

require 'rails_helper'

describe 'admin REDCap project retrieve records buttons', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include Redcap::RedcapSupport

  before(:example) do
    SetupHelper.feature_setup
    change_setting('TwoFactorAuthDisabledForUser', true)

    make_an_admin
    create_admin_matching_user
    @projects = setup_redcap_project_admin_configs
    @project = @projects.first
    setup_file_fields

    # Close any extra windows from previous tests
    windows.last.close while windows.length > 1 if respond_to?(:windows)

    admin_sign_in_with_2fa
  end

  def navigate_to_project_edit(project)
    visit '/redcap/project_admins'
    expect(page).to have_css("#admin-item-#{project.id}", wait: 10)

    within "#admin-item-#{project.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    expect(page).to have_content(project.name, wait: 10)
  end

  it 'shows split buttons when export_only_updated_records is "manual"' do
    project = @project_admin
    project.current_admin = @admin
    project.transfer_mode = 'manual'
    project.data_options.export_only_updated_records = 'manual'
    project.disabled = false
    project.save!

    # Ensure file store and dynamic model are ready
    project.create_file_store unless project.file_store
    project.reload

    expect(project.dynamic_model_ready?).to be true
    expect(project.export_only_updated_records_for_manual?).to be true

    navigate_to_project_edit(project)

    # Check that the split buttons are visible
    expect(page).to have_css('.project-admin-actions-block')

    within '.project-admin-actions-block' do
      # Should have the "retrieve records" section header
      expect(page).to have_content('retrieve records', wait: 5)
      # Should have the "retrieve all" button
      expect(page).to have_link('retrieve all')
    end
  end

  it 'shows split buttons when export_only_updated_records is "always"' do
    project = @project_admin
    project.current_admin = @admin
    project.transfer_mode = 'scheduled'
    project.frequency = '1 hour'
    project.data_options.export_only_updated_records = 'always'
    project.disabled = false
    project.save!

    # Ensure file store and dynamic model are ready
    project.create_file_store unless project.file_store
    project.reload

    expect(project.dynamic_model_ready?).to be true
    expect(project.export_only_updated_records_for_manual?).to be true

    navigate_to_project_edit(project)

    # Check that the split buttons are visible
    expect(page).to have_css('.project-admin-actions-block')

    within '.project-admin-actions-block' do
      # Should have the "retrieve records" section header
      expect(page).to have_content('retrieve records', wait: 5)
      # Should have the "retrieve all" button
      expect(page).to have_link('retrieve all')
    end
  end

  it 'shows standard button when export_only_updated_records is "scheduled"' do
    project = @project_admin
    project.current_admin = @admin
    project.transfer_mode = 'scheduled'
    project.frequency = '1 hour'
    project.data_options.export_only_updated_records = 'scheduled'
    project.disabled = false
    project.save!

    # Ensure file store and dynamic model are ready
    project.create_file_store unless project.file_store
    project.reload

    expect(project.dynamic_model_ready?).to be true
    expect(project.export_only_updated_records_for_manual?).to be false

    navigate_to_project_edit(project)

    # Check that only the standard button is visible
    expect(page).to have_css('.project-admin-actions-block')

    within '.project-admin-actions-block' do
      # Should have the standard "retrieve records" link
      expect(page).to have_link('retrieve records', wait: 5)
      # Should NOT have the "retrieve all" button (split buttons indicator)
      expect(page).not_to have_link('retrieve all')
    end
  end

  it 'shows standard button when export_only_updated_records is not set' do
    project = @project_admin
    project.current_admin = @admin
    project.transfer_mode = 'manual'
    project.data_options.export_only_updated_records = nil
    project.disabled = false
    project.save!

    # Ensure file store and dynamic model are ready
    project.create_file_store unless project.file_store
    project.reload

    expect(project.dynamic_model_ready?).to be true
    expect(project.export_only_updated_records_for_manual?).to be false

    navigate_to_project_edit(project)

    # Check that only the standard button is visible
    expect(page).to have_css('.project-admin-actions-block')

    within '.project-admin-actions-block' do
      # Should have the standard "retrieve records" link
      expect(page).to have_link('retrieve records', wait: 5)
      # Should NOT have the "retrieve all" button (split buttons indicator)
      expect(page).not_to have_link('retrieve all')
    end
  end

  it 'split button includes date from last record update' do
    project = @project_admin
    project.current_admin = @admin
    project.transfer_mode = 'manual'
    project.data_options.export_only_updated_records = 'manual'
    project.disabled = false
    project.save!

    # Ensure file store and dynamic model are ready
    project.create_file_store unless project.file_store
    project.reload

    # Insert a record to establish a date
    model_class = project.dynamic_storage.dynamic_model.implementation_class
    test_time = 5.minutes.ago
    ActiveRecord::Base.connection.execute(
      "INSERT INTO #{model_class.table_name} (record_id, created_at, updated_at) VALUES ('test-btn-99999', '#{test_time.to_fs(:db)}', '#{test_time.to_fs(:db)}')"
    )

    # Verify the record exists and the date_range is set
    expect(model_class.count).to be > 0
    expect(project.date_range_begin_for_manual_pull).to be_a Time

    navigate_to_project_edit(project)

    within '.project-admin-actions-block' do
      # The button text should include "since" with a date (format: MM/DD/YYYY H:MM am/pm)
      expect(page).to have_css('a', text: %r{since \d{2}/\d{2}/\d{4}})
    end
  end
end
