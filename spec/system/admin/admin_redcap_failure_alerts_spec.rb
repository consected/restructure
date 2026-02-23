# frozen_string_literal: true

# Tests for admin REDCap failure alerts displayed in the collapsed alerts panel
# on the admin index page (updated for Issue #905 - alerts moved from popovers
# on h3 headings to a collapsed panel at the top of the page).

require 'rails_helper'

describe 'admin REDCap failure alerts', js: true, driver: $browser_driver do
  include ModelSupport
  include Redcap::RedcapSupport
  include AdminActionsSetup

  before(:example) do
    SetupHelper.feature_setup
    make_an_admin
    create_admin_matching_user
    @projects = setup_redcap_project_admin_configs
  end

  it 'shows no REDCap alerts when no projects have failed' do
    # Ensure all projects are successful
    Redcap::ProjectAdmin.active.each do |rc|
      rc.update_columns(status: Redcap::ProjectAdmin::Statuses[:scheduled_run_successful])
    end

    admin_sign_in_with_2fa

    # Should be on admin index page
    expect(page).to have_content('Admin')
    expect(page).to have_content('REDCap')

    # If the alerts panel exists (due to other non-REDCap issues), it should not contain REDCap alerts
    if page.has_css?('#admin-alerts-panel')
      find('#admin-alerts-panel .panel-heading a').click
      sleep 0.5
      within('#admin-alerts-collapse') do
        expect(page).not_to have_css('.label', text: 'REDCap')
      end
    end
  end

  it 'shows alerts panel when projects have failed' do
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

    # Alerts panel should be present with alert icon
    expect(page).to have_css('#admin-alerts-panel')
    within('#admin-alerts-panel .panel-heading') do
      expect(page).to have_css('.glyphicon-alert')
    end
  end

  it 'alerts panel content includes failed project details when expanded' do
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

    # Expand the alerts panel
    find('#admin-alerts-panel .panel-heading a').click
    sleep 0.5

    # Verify panel content includes project details
    within('#admin-alerts-collapse') do
      expect(page).to have_content(project_name)
      expect(page).to have_content(project_study)
      expect(page).to have_content('REDCap')
    end
  end

  it 'alerts panel lists multiple failed projects' do
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

    # Expand the alerts panel
    find('#admin-alerts-panel .panel-heading a').click
    sleep 0.5

    # Verify both projects are listed in the panel content
    within('#admin-alerts-collapse') do
      expect(page).to have_content(project1_name)
      expect(page).to have_content(project1_study)
      expect(page).to have_content(project2_name)
      expect(page).to have_content(project2_study)
    end
  end

  it 'only shows REDCap alerts when admin has REDCap permissions and ref-data access' do
    # Create a failed project
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    rc.frequency = '1 hour'
    rc.transfer_mode = 'scheduled'
    rc.save!
    rc.update_columns(status: Redcap::ProjectAdmin::Statuses[:scheduled_run_failed])

    admin_sign_in_with_2fa

    # With proper permissions, alerts panel should be visible with REDCap alerts
    expect(page).to have_css('#admin-alerts-panel')

    # Expand the panel and verify REDCap category label
    find('#admin-alerts-panel .panel-heading a').click
    sleep 0.5

    within('#admin-alerts-collapse') do
      expect(page).to have_content('REDCap')
    end
  end
end
