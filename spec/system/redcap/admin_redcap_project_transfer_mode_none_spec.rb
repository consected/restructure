# frozen_string_literal: true

require 'rails_helper'

describe 'admin REDCap project with transfer mode "none"', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include Redcap::RedcapSupport

  before(:example) do
    SetupHelper.feature_setup
    change_setting('TwoFactorAuthDisabledForUser', true)

    make_an_admin
    create_admin_matching_user
    @projects = setup_redcap_project_admin_configs

    # Close any extra windows from previous tests
    windows.last.close while windows.length > 1 if respond_to?(:windows)

    admin_sign_in_with_2fa
  end

  it 'hides action buttons when transfer_mode is "none"' do
    # Create or update a project with transfer_mode = 'none'
    project = Redcap::ProjectAdmin.active.first
    project.current_admin = @admin
    project.transfer_mode = 'none'
    project.frequency = nil
    project.save!

    # Ensure file store exists
    project.create_file_store unless project.file_store
    project.reload

    project_id = project.id

    # Navigate directly to the REDCap Project Admins page
    visit '/redcap/project_admins'

    # Wait for the projects list to load
    expect(page).to have_content(project.name, wait: 10)

    # Check that the actions block is not visible
    expect(page).not_to have_css('.project-admin-actions-block')
    expect(page).not_to have_link('retrieve records')
    expect(page).not_to have_link('retrieve latest redcap configuration')
    expect(page).not_to have_link('retrieve user list')
    expect(page).not_to have_link('retrieve data collection instruments list')
    expect(page).not_to have_link('retrieve event logs')
    expect(page).not_to have_link('dump project archive to filestore')
    expect(page).not_to have_link('update dynamic model')
    expect(page).not_to have_link('force reconfiguration')
  end

  it 'shows action buttons when transfer_mode is "scheduled"' do
    project = Redcap::ProjectAdmin.active.first
    project.current_admin = @admin
    project.transfer_mode = 'scheduled'
    project.frequency = '1 hour'
    project.disabled = false
    project.save!

    # Ensure file store exists
    project.create_file_store unless project.file_store
    project.reload

    # Verify the project settings
    expect(project.transfer_mode).to eq('scheduled')
    expect(project.enabled?).to be true

    project_id = project.id

    # Navigate directly to the REDCap Project Admins page
    visit '/redcap/project_admins'

    # Wait for the projects list to load
    expect(page).to have_css("#admin-item-#{project_id}", wait: 10)

    # Click the edit button for this project
    within "#admin-item-#{project_id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    # Wait for the edit form to load
    expect(page).to have_content(project.name, wait: 10)

    # Check that the actions block is visible
    expect(page).to have_css('.project-admin-actions-block')
    # NOTE: Specific action links only appear if dynamic_model_ready? is true
    # The presence of the action block itself indicates transfer_mode is not 'none'
  end

  it 'shows action buttons when transfer_mode is "manual"' do
    project = Redcap::ProjectAdmin.active.first
    project.current_admin = @admin
    project.transfer_mode = 'manual'
    project.frequency = nil
    project.disabled = false
    project.save!

    # Ensure file store exists
    project.create_file_store unless project.file_store
    project.reload

    # Verify the project settings
    expect(project.transfer_mode).to eq('manual')
    expect(project.enabled?).to be true

    project_id = project.id

    # Navigate directly to the REDCap Project Admins page
    visit '/redcap/project_admins'

    # Wait for the projects list to load
    expect(page).to have_css("#admin-item-#{project_id}", wait: 10)

    # Click the edit button for this project
    within "#admin-item-#{project_id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    # Wait for the edit form to load
    expect(page).to have_content(project.name, wait: 10)

    # Check that the actions block is visible
    expect(page).to have_css('.project-admin-actions-block')
    # NOTE: Specific action links only appear if dynamic_model_ready? is true
    # The presence of the action block itself indicates transfer_mode is not 'none'
  end

  it 'displays transfer mode status correctly for "none"' do
    project = Redcap::ProjectAdmin.active.first
    project.current_admin = @admin
    project.transfer_mode = 'none'
    project.save!

    # Ensure file store exists
    project.create_file_store unless project.file_store
    project.reload

    project_id = project.id

    # Navigate directly to the REDCap Project Admins page
    visit '/redcap/project_admins'

    # Wait for the projects list to load
    expect(page).to have_css("#admin-item-#{project_id}", wait: 10)

    # Click the edit button for this project
    within "#admin-item-#{project_id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    # Wait for the edit form to load
    expect(page).to have_content(project.name, wait: 10)

    # Check that transfer mode displays as "none"
    expect(page).to have_content('Transfer mode')
    expect(page).to have_content('none')
  end
end
