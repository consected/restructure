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

  # Mark a REDCap project as failed with the given status
  # @param project [Redcap::ProjectAdmin] the project to mark as failed
  # @param frequency [String] the scheduling frequency
  # @param status_key [Symbol] the failure status key from Redcap::ProjectAdmin::Statuses
  def mark_project_failed(project, frequency: '1 hour', status_key: :scheduled_run_failed)
    project.current_admin = @admin
    project.frequency = frequency
    project.transfer_mode = 'scheduled'
    project.save!
    project.update_columns(status: Redcap::ProjectAdmin::Statuses[status_key])
  end

  it 'shows alerts panel when projects have failed' do
    mark_project_failed(Redcap::ProjectAdmin.active.first)
    mark_project_failed(Redcap::ProjectAdmin.active.second, frequency: '30 minutes', status_key: :manual_run_failed)

    admin_sign_in_with_2fa

    expect(page).to have_content('Admin')
    expect(page).to have_css('#admin-alerts-panel')
    within('#admin-alerts-panel .panel-heading') do
      expect(page).to have_css('.glyphicon-alert')
    end
  end

  it 'alerts panel content includes failed project details when expanded' do
    rc = Redcap::ProjectAdmin.active.first
    mark_project_failed(rc)
    rc.reload

    admin_sign_in_with_2fa

    find('#admin-alerts-panel .panel-heading a').click
    sleep 0.5

    within('#admin-alerts-collapse') do
      expect(page).to have_content(rc.name)
      expect(page).to have_content(rc.study)
      expect(page).to have_content('REDCap')
    end
  end

  it 'alerts panel lists multiple failed projects' do
    rc1 = Redcap::ProjectAdmin.active.first
    rc2 = Redcap::ProjectAdmin.active.second
    mark_project_failed(rc1)
    mark_project_failed(rc2, frequency: '2 hours', status_key: :request_failed)

    admin_sign_in_with_2fa

    find('#admin-alerts-panel .panel-heading a').click
    sleep 0.5

    within('#admin-alerts-collapse') do
      expect(page).to have_content(rc1.name)
      expect(page).to have_content(rc1.study)
      expect(page).to have_content(rc2.name)
      expect(page).to have_content(rc2.study)
    end
  end

  it 'shows REDCap alerts when admin has REDCap permissions and ref-data access' do
    mark_project_failed(Redcap::ProjectAdmin.active.first)

    admin_sign_in_with_2fa

    expect(page).to have_css('#admin-alerts-panel')

    find('#admin-alerts-panel .panel-heading a').click
    sleep 0.5

    within('#admin-alerts-collapse') do
      expect(page).to have_content('REDCap')
    end
  end
end
