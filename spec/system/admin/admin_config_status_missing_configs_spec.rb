# frozen_string_literal: true

# Tests the "Missing Configurations" collapsible panel in the app type config status partial.
#
# The _config_status.html.erb partial renders on both the admin index page and
# the app type components page. When any of these conditions are unmet:
#   - Filestore filesystem path exists for the app type
#   - App type ID included in OnlyLoadAppTypes setting
#   - Default schema in the database search path
# a collapsed "Missing Configurations" panel-warning block appears with
# remediation instructions. When all conditions are satisfied, the block
# is hidden entirely.

require 'rails_helper'

RSpec.describe 'Admin config status missing configurations panel', js: true, type: :system do
  include MasterSupport
  include FeatureSupport

  before(:all) do
    change_setting('TwoFactorAuthDisabledForAdmin', true)
    create_admin
  end

  before(:each) do
    login_as(@admin, scope: :admin)
  end

  # Mock Admin::ServerInfo to avoid unrelated server alerts interfering
  def mock_healthy_server_info
    si = Admin::ServerInfo.new(@admin)
    allow(Admin::ServerInfo).to receive(:new).and_return(si)
    allow(si).to receive(:configuration_failed_reason).and_return([])
    allow(si).to receive(:configuration_successful).and_return(true)
  end

  describe 'when a configuration is missing' do
    it 'shows a collapsed Missing Configurations panel with remediation instructions' do
      mock_healthy_server_info

      # Force a missing configuration: filestore path does not exist
      allow(NfsStore::Manage::Filesystem).to receive(:app_type_containers_path_exists?).and_return(false)

      visit '/'
      finish_page_loading

      within('.config-status-block') do
        expect(page).to have_css('.panel-warning.status-extra-info')

        within('.panel-warning.status-extra-info') do
          # Panel header shows "Missing Configurations" with a warning icon
          expect(page).to have_css('.glyphicon-exclamation-sign')
          expect(page).to have_content('Missing Configurations')

          # The panel body starts collapsed
          expect(page).not_to have_css('.panel-collapse.in')
        end
      end
    end

    it 'shows filestore setup instructions when expanded' do
      mock_healthy_server_info
      allow(NfsStore::Manage::Filesystem).to receive(:app_type_containers_path_exists?).and_return(false)

      visit '/'
      finish_page_loading

      within('.config-status-block .panel-warning.status-extra-info') do
        find('.panel-heading a').click
        sleep 0.5

        expect(page).to have_css('.panel-collapse.in')
        expect(page).to have_content('Configure the filestore app filesystem')
        expect(page).to have_content('setup_filestore_app.sh')
      end
    end

    it 'shows schema remediation when default schema is not in search path' do
      mock_healthy_server_info

      # Filestore exists, but schema is missing from search path
      allow(NfsStore::Manage::Filesystem).to receive(:app_type_containers_path_exists?).and_return(true)
      allow(Admin::MigrationGenerator).to receive(:current_search_paths).and_return(%w[unrelated_schema])

      visit '/'
      finish_page_loading

      within('.config-status-block .panel-warning.status-extra-info') do
        find('.panel-heading a').click
        sleep 0.5

        expect(page).to have_content('Add default schema to database search path')
        expect(page).to have_content('FPHS_POSTGRESQL_SCHEMA')
      end
    end
  end

  describe 'when all configurations are present' do
    it 'does not show the Missing Configurations panel' do
      mock_healthy_server_info

      # All three conditions are satisfied
      allow(NfsStore::Manage::Filesystem).to receive(:app_type_containers_path_exists?).and_return(true)
      # OnlyLoadAppTypes is nil/empty in test env, so missing_load_app_type is falsy
      # Schema is already in search path in test env for the default app type

      visit '/'
      finish_page_loading

      within('.config-status-block') do
        expect(page).not_to have_css('.panel-warning.status-extra-info')
      end
    end
  end
end
