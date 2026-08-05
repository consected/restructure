# frozen_string_literal: true

require 'rails_helper'

# Tests for issue #1260 - allow an admin to remove a REDCap user from a
# project directly from the "Users" panel of the project admin edit form.
# Each "not disabled" user should show a delete icon, which opens a
# confirmation dialog (matching the "update dynamic model" button pattern).
# Confirming calls the REDCap API to remove the user, then reloads the full
# user list in a background job.
describe 'admin REDCap project remove user button', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include Redcap::RedcapSupport
  include FeatureSupport

  before(:example) do
    SetupHelper.feature_setup
    change_setting('TwoFactorAuthDisabledForUser', true)

    make_an_admin
    create_admin_matching_user
    @projects = setup_redcap_project_admin_configs
    @project = @projects.first

    # Populate the locally stored REDCap user list from the initial (full) fixture
    @project_admin = Redcap::ProjectAdmin.active.first
    @project_admin.current_admin = @admin
    Redcap::ProjectUsers.new(@project_admin).retrieve_validate_store

    # Close any extra windows from previous tests
    windows.last.close while windows.length > 1 if respond_to?(:windows)

    admin_sign_in_with_2fa
  end

  def navigate_to_users_tab(project)
    visit '/redcap/project_admins'
    expect(page).to have_css("#admin-item-#{project.id}", wait: 10)

    within "#admin-item-#{project.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    expect(page).to have_content(project.name, wait: 10)
    find('.nav-tabs a[aria-controls="def-users-block"]', visible: true).click
    expect(page).to have_css('.admin-options-ref-users-block', wait: 10)
  end

  it 'shows a delete icon only for users that are not disabled' do
    project = @project_admin
    project.transfer_mode = 'manual'
    project.save!

    disabled_user = Redcap::ProjectUser.where(redcap_project_admin: project).first
    disabled_user.current_admin = @admin
    disabled_user.update!(disabled: true)

    active_username = Redcap::ProjectUser.where(redcap_project_admin: project)
                                         .where.not(id: disabled_user.id).first.username

    navigate_to_users_tab(project)

    within '.admin-options-ref-users-block' do
      within('tr', text: disabled_user.username) do
        expect(page).not_to have_css('a.remove-redcap-user')
      end

      within('tr', text: active_username) do
        expect(page).to have_css('a.remove-redcap-user')
      end
    end
  end

  it 'removes the user from REDCap after confirming the delete dialog' do
    project = @project_admin
    project.transfer_mode = 'manual'
    project.save!

    username = 'h16'
    stub_request_remove_project_user @project[:server_url], @project[:api_key], username: username
    stub_request_project_users_deleted @project[:server_url], @project[:api_key]

    expect(Redcap::ProjectUser.find_by(redcap_project_admin: project, username: username).disabled).to be_falsey

    navigate_to_users_tab(project)

    within('tr', text: username) do
      find('a.remove-redcap-user').click
    end

    expect(page).to have_css('.modal', visible: true, wait: 5)

    within '.modal' do
      expect(page).to have_content('remove')

      click_link 'remove user'
    end
    finish_page_loading

    # Wait for the background job to complete and refresh the stored user list
    start_time = Time.now
    loop do
      break if Redcap::ProjectUser.find_by(redcap_project_admin: project, username: username).disabled
      break if (Time.now - start_time) > 10

      sleep 0.5
    end

    expect(Redcap::ProjectUser.find_by(redcap_project_admin: project, username: username).disabled).to be(true),
                                                                                                       "User '#{username}' was not disabled within 10 seconds"

    audit = Redcap::ClientRequest.where(action: 'user').order(created_at: :desc)
                                 .find { |cr| cr.result['api_action'] == 'delete' }
    expect(audit).to be_present
  end
end
