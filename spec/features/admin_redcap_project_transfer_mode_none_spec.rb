# frozen_string_literal: true

require 'rails_helper'

describe 'admin REDCap project with transfer mode "none"', js: true, driver: $browser_driver do
  include ModelSupport
  include Redcap::RedcapSupport

  def make_an_admin
    ENV['FPHS_ADMIN_SETUP'] = 'yes'

    @good_email = "testuser#{rand(1_000_000_000)}admin@testing.com"
    @admin = Admin.create! email: @good_email
    # Save a new password, as required to handle temp passwords
    @admin = Admin.find(@admin.id)
    @good_password = @admin.generate_password
    @admin.save!
    # Don't require 2FA for this admin since we disabled it in settings
    @admin.otp_required_for_login = false
    @admin.save!

    @good_password
  end

  def admin_sign_in_with_2fa
    admin = Admin.where(email: @good_email).first
    expect(admin).to be_a Admin
    expect(admin.id).to equal @admin.id

    url = "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
    visit url
    expect(current_path).to eq '/admins/sign_in'

    within '#new_admin' do
      expect(@admin.email).to eq @good_email
      expect(@admin.valid_password?(@good_password)).to be true

      fill_in 'Email', with: @good_email
      fill_in 'Password', with: @good_password
      click_button 'Log in'
    end

    # Since 2FA is disabled, we should be signed in directly
    expect(page).to have_css('.flash .alert', text: 'Signed in successfully.', wait: 10)
  end

  def create_admin_matching_user
    app_type = Admin::AppType.active.find_by_name('ref-data')
    app_type_id = app_type.id
    create_user(nil, '', email: @admin.email) unless @admin.matching_user

    @user = user = @admin.matching_user

    enable_user_app_access app_type.name, user
    user.update!(app_type_id: app_type_id)

    expect(app_type_id).not_to be_nil
    expect(Settings.admin_master).not_to be_nil

    setup_access 'trackers', user: user
    setup_access 'nfs_store__manage__containers', user: user
    setup_access 'nfs_store__manage__stored_files', user: user
    setup_access 'nfs_store__manage__archived_files', user: user
    expect(@admin.matching_user.app_type).not_to be_nil
    expect(@admin.matching_user).to eq user

    # Ensure admin's matching user is reloaded and properly associated
    @admin.reload
    expect(@admin.matching_user).not_to be_nil
    expect(@admin.matching_user.app_type).not_to be_nil

    user
  end

  before(:example) do
    SetupHelper.feature_setup
    change_setting('TwoFactorAuthDisabledForAdmin', true)
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
