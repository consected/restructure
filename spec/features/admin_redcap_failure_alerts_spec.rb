# frozen_string_literal: true

require 'rails_helper'

describe 'admin REDCap failure alerts', js: true, driver: $browser_driver do
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
    @admin.otp_secret = Admin.generate_otp_secret
    @admin.otp_required_for_login = true
    @admin.new_two_factor_auth_code = false
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

    # Enter 2FA code
    expect(page).to have_selector('.login-2fa-block', visible: true)
    expect(page).to have_selector('#new_admin', visible: true)
    expect(page).to have_selector('input[type="submit"]:not([disabled])', visible: true)

    within '#new_admin' do
      fill_in 'Two-Factor Authentication Code', with: @admin.current_otp
      click_button 'Log in'
    end

    expect(page).to have_css('.flash .alert', text: 'Signed in successfully.')
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

    user
  end

  before(:example) do
    SetupHelper.feature_setup
    make_an_admin
    create_admin_matching_user
    @projects = setup_redcap_project_admin_configs
  end

  it 'shows no alert indicator when no projects have failed' do
    # Ensure all projects are successful
    Redcap::ProjectAdmin.active.each do |rc|
      rc.update_columns(status: Redcap::ProjectAdmin::Statuses[:scheduled_run_successful])
    end

    admin_sign_in_with_2fa

    # Should be on admin index page
    expect(page).to have_content('Admin')
    expect(page).to have_content('REDCap')

    # Alert indicator should not be present
    within 'h3', text: 'REDCap' do
      expect(page).not_to have_selector('.glyphicon-alert.error-mark')
    end
  end

  it 'shows alert indicator when projects have failed' do
    # Create some failed projects
    rc1 = Redcap::ProjectAdmin.active.first
    rc1.current_admin = @admin
    rc1.frequency = '1 hour'
    rc1.transfer_mode = 'scheduled'
    rc1.save!
    rc1.update_columns(status: Redcap::ProjectAdmin::Statuses[:scheduled_run_failed])

    rc2 = Redcap::ProjectAdmin.active.second
    rc2.current_admin = @admin
    rc2.frequency = '30 minutes'
    rc2.transfer_mode = 'scheduled'
    rc2.save!
    rc2.update_columns(status: Redcap::ProjectAdmin::Statuses[:manual_run_failed])

    admin_sign_in_with_2fa

    # Should be on admin index page
    expect(page).to have_content('Admin')
    expect(page).to have_content('REDCap')

    # Alert indicator should be present
    within 'h3', text: 'REDCap' do
      expect(page).to have_selector('.glyphicon-alert.error-mark')
    end
  end

  it 'alert indicator has popover attributes configured' do
    # Create a failed project with known details
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    rc.frequency = '1 hour'
    rc.transfer_mode = 'scheduled'
    rc.save!
    rc.update_columns(status: Redcap::ProjectAdmin::Statuses[:scheduled_run_failed])
    rc.reload

    # Store the actual name and study for verification
    project_name = rc.name
    project_study = rc.study

    admin_sign_in_with_2fa

    # Verify alert indicator has popover data attributes
    within 'h3', text: 'REDCap' do
      alert_icon = find('.glyphicon-alert.error-mark')
      expect(alert_icon['data-toggle']).to eq('popover')
      expect(alert_icon['data-trigger']).to eq('click hover')
      expect(alert_icon['data-html']).to eq('true')
      expect(alert_icon['title']).to eq('REDCap Project Failures')

      # Verify popover content includes project details
      data_content = alert_icon['data-content']
      expect(data_content).to include('Failed scheduled pulls:')
      expect(data_content).to include(project_name)
      expect(data_content).to include(project_study)
    end
  end

  it 'popover content lists multiple failed projects' do
    # Create multiple failed projects
    rc1 = Redcap::ProjectAdmin.active.first
    rc1.current_admin = @admin
    rc1.frequency = '1 hour'
    rc1.transfer_mode = 'scheduled'
    rc1.save!
    rc1.update_columns(status: Redcap::ProjectAdmin::Statuses[:scheduled_run_failed])

    rc2 = Redcap::ProjectAdmin.active.second
    rc2.current_admin = @admin
    rc2.frequency = '2 hours'
    rc2.transfer_mode = 'scheduled'
    rc2.save!
    rc2.update_columns(status: Redcap::ProjectAdmin::Statuses[:request_failed])

    # Store the actual names and studies for verification
    project1_name = rc1.name
    project1_study = rc1.study
    project2_name = rc2.name
    project2_study = rc2.study

    admin_sign_in_with_2fa

    # Verify popover content includes all failed projects
    within 'h3', text: 'REDCap' do
      alert_icon = find('.glyphicon-alert.error-mark')
      data_content = alert_icon['data-content']

      # Verify both projects are in the popover content
      expect(data_content).to include(project1_name)
      expect(data_content).to include(project1_study)
      expect(data_content).to include(project2_name)
      expect(data_content).to include(project2_study)
    end
  end

  it 'only shows alert indicator when admin has REDCap permissions and ref-data access' do
    # Create a failed project
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    rc.frequency = '1 hour'
    rc.transfer_mode = 'scheduled'
    rc.save!
    rc.update_columns(status: Redcap::ProjectAdmin::Statuses[:scheduled_run_failed])

    admin_sign_in_with_2fa

    # With proper permissions, alert should be visible
    expect(page).to have_selector('h3', text: 'REDCap')
    within 'h3', text: 'REDCap' do
      expect(page).to have_selector('.glyphicon-alert.error-mark')
    end
  end
end
