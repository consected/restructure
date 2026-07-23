# frozen_string_literal: true

# Admin API Definitions Panel Spec
#
# Tests the API tab added to dynamic definition admin panels (dynamic models,
# activity logs, external identifiers) and reports. Verifies that the tab
# displays correct REST API endpoints, curl examples with placeholder variables,
# field definitions (excluding standard fields), save trigger usage examples,
# and copy-to-clipboard buttons.
#
# Issue: https://github.com/consected/restructure/issues/652

require 'rails_helper'

describe 'admin API definitions panel', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport

  before(:all) do
    SetupHelper.feature_setup
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    make_an_admin
  end

  describe 'dynamic models' do
    it 'displays the API tab with endpoints, curl examples, fields, and save trigger' do
      dm = DynamicModel.active.find(&:table_or_view_ready?)
      skip 'No active dynamic models with ready tables found' unless dm

      admin_sign_in_with_2fa

      visit '/admin/dynamic_models'
      finish_page_loading

      within "#admin-item-#{dm.id}" do
        find('a.edit-entity.glyphicon-pencil').click
      end

      expect(page).to have_css('.nav-tabs', wait: 10)

      # Click the API tab
      find('.nav-tabs a[aria-controls="api-definitions"]', visible: true).click
      expect(page).to have_css('#api-definitions', visible: true)
      finish_page_loading

      within '#api-definitions' do
        # Verify the API heading
        expect(page).to have_content('API')

        # Verify resource name is displayed
        expect(page).to have_css('.api-panel')
        expect(page).to have_content('resource name')
        expect(page).to have_content(dm.resource_name)

        # Verify endpoint sections are present
        expect(page).to have_content('endpoints')
        expect(page).to have_content('Index (list all)')
        expect(page).to have_content('Read (show one)')
        expect(page).to have_content('Create')
        expect(page).to have_content('Update')

        # Verify endpoint paths contain the correct route segments
        expect(page).to have_content(dm.base_route_segments)

        # Verify paths are correctly nested under /masters/ or not
        expect(page).to have_content('/masters/{{master_id}}/') if dm.foreign_key_name.present?

        # Verify HTTP methods are shown
        expect(page).to have_content('GET')
        expect(page).to have_content('POST')
        expect(page).to have_content('PUT')

        # Verify curl examples section
        expect(page).to have_content('curl examples')
        expect(page).to have_css('.api-panel__curl-block', minimum: 4)
        expect(page).to have_content('{{base_url}}')
        expect(page).to have_content('{{app_type_id}}')
        expect(page).to have_content('{{user_email}}')
        expect(page).to have_content('{{api_token}}')

        # Verify fields section
        expect(page).to have_content('fields')
        expect(page).to have_css('.api-panel__fields-list-block')

        # Verify standard fields are excluded from the fields list
        fields_block = find('.api-panel__fields-list-block')
        fields_text = fields_block.text
        expect(fields_text).not_to include('created_at')
        expect(fields_text).not_to include('updated_at')
        expect(fields_text).not_to include('master_id')
        expect(fields_text).not_to include('user_id')

        # Verify save trigger section
        expect(page).to have_content('save trigger usage')
        expect(page).to have_css('.api-panel__save-trigger-block')
        trigger_block = find('.api-panel__save-trigger-block')
        trigger_text = trigger_block.text
        expect(trigger_text).to include('pull_external_data')
        expect(trigger_text).to include('get_record')
        expect(trigger_text).to include('create_record')

        # Verify copy-to-clipboard buttons are present
        expect(page).to have_css('.api-panel__copy-btn', minimum: 4)
      end
    end

    it 'generates correct base path for master-nested definition' do
      dm = DynamicModel.active.find { |d| d.table_or_view_ready? && d.foreign_key_name.present? }
      skip 'No master-nested dynamic model found' unless dm

      admin_sign_in_with_2fa

      visit '/admin/dynamic_models'
      finish_page_loading

      within "#admin-item-#{dm.id}" do
        find('a.edit-entity.glyphicon-pencil').click
      end

      expect(page).to have_css('.nav-tabs', wait: 10)

      find('.nav-tabs a[aria-controls="api-definitions"]', visible: true).click
      expect(page).to have_css('#api-definitions', visible: true)

      within '#api-definitions' do
        # Verify master-nested paths appear in curl examples
        expect(page).to have_content('/masters/{{master_id}}/')
      end
    end

    it 'omits /masters/ prefix for non-master-nested definition' do
      dm = DynamicModel.active.find { |d| d.table_or_view_ready? && d.foreign_key_name.blank? }
      skip 'No non-master-nested dynamic model found' unless dm

      admin_sign_in_with_2fa

      visit '/admin/dynamic_models'
      finish_page_loading

      within "#admin-item-#{dm.id}" do
        find('a.edit-entity.glyphicon-pencil').click
      end

      expect(page).to have_css('.nav-tabs', wait: 10)

      find('.nav-tabs a[aria-controls="api-definitions"]', visible: true).click
      expect(page).to have_css('#api-definitions', visible: true)

      within '#api-definitions' do
        # Non-master-nested paths should not include /masters/{{master_id}}/
        expect(page).not_to have_content('/masters/{{master_id}}/')
        # But should still show routes starting with /dynamic_model/
        expect(page).to have_content("/dynamic_model/#{dm.table_name}")
      end
    end

    it 'shows not-available message when table is not ready' do
      dm = DynamicModel.active.find { |d| !d.table_or_view_ready? }
      skip 'No active dynamic model without ready table found' unless dm

      admin_sign_in_with_2fa

      visit '/admin/dynamic_models'
      finish_page_loading

      within "#admin-item-#{dm.id}" do
        find('a.edit-entity.glyphicon-pencil').click
      end

      expect(page).to have_css('.nav-tabs', wait: 10)

      find('.nav-tabs a[aria-controls="api-definitions"]', visible: true).click
      expect(page).to have_css('#api-definitions', visible: true)

      within '#api-definitions' do
        expect(page).to have_content('API definitions are not available')
        expect(page).not_to have_css('.api-panel')
      end
    end
  end

  describe 'activity logs' do
    it 'displays the API tab with endpoints including extra log types' do
      al = ActivityLog.active.first
      skip 'No active activity logs found' unless al

      admin_sign_in_with_2fa

      visit '/admin/activity_logs'
      finish_page_loading

      within "#admin-item-#{al.id}" do
        find('a.edit-entity.glyphicon-pencil').click
      end

      expect(page).to have_css('.nav-tabs', wait: 10)

      find('.nav-tabs a[aria-controls="api-definitions"]', visible: true).click
      expect(page).to have_css('#api-definitions', visible: true)
      finish_page_loading

      within '#api-definitions' do
        # Verify API panel renders
        expect(page).to have_css('.api-panel')
        expect(page).to have_content('resource name')
        expect(page).to have_content(al.resource_name)

        # Verify standard endpoints
        expect(page).to have_content('Index (list all)')
        expect(page).to have_content('Read (show one)')
        expect(page).to have_content('Create')
        expect(page).to have_content('Update')

        # Activity logs should always be master-nested
        expect(page).to have_content('/masters/{{master_id}}/')
        expect(page).to have_content(al.base_route_segments)

        # Verify extra_log_type endpoints if present
        non_standard = al.option_configs_names&.reject { |n| n.in?(%i[primary blank_log]) }
        non_standard&.each do |elt_name|
          expect(page).to have_content("Create (#{elt_name})")
          expect(page).to have_content("Read (#{elt_name})")
        end

        # Verify curl examples
        expect(page).to have_css('.api-panel__curl-block', minimum: 4)

        # Verify fields section
        expect(page).to have_css('.api-panel__fields-list-block')

        # Verify save trigger section
        expect(page).to have_css('.api-panel__save-trigger-block')
      end
    end
  end

  describe 'external identifiers' do
    it 'displays the API tab with endpoints and fields' do
      ei = ExternalIdentifier.active.find(&:table_or_view_ready?)
      skip 'No active external identifiers with ready tables found' unless ei

      admin_sign_in_with_2fa

      visit '/admin/external_identifiers'
      finish_page_loading

      expect(page).to have_css("#admin-item-#{ei.id}", wait: 10)

      within "#admin-item-#{ei.id}" do
        find('a.edit-entity.glyphicon-pencil').click
      end

      expect(page).to have_css('.admin-edit-form', wait: 10)
      sleep 1

      within '.admin-edit-form' do
        expect(page).to have_css('.nav-tabs', wait: 10)
        find('.nav-tabs a[aria-controls="api-definitions"]', visible: true).click
      end

      expect(page).to have_css('#api-definitions', visible: true, wait: 10)
      finish_page_loading

      within '#api-definitions' do
        expect(page).to have_css('.api-panel')
        expect(page).to have_content('resource name')

        # Verify endpoints
        expect(page).to have_content('Index (list all)')
        expect(page).to have_content('Read (show one)')
        expect(page).to have_content('Create')
        expect(page).to have_content('Update')

        # External identifiers are always master-nested
        expect(page).to have_content('/masters/{{master_id}}/')
        expect(page).to have_content(ei.base_route_segments)

        # Verify curl examples with placeholders
        expect(page).to have_css('.api-panel__curl-block', minimum: 4)
        expect(page).to have_content('{{base_url}}')

        # Verify fields section
        expect(page).to have_css('.api-panel__fields-list-block')

        # Verify save trigger
        expect(page).to have_css('.api-panel__save-trigger-block')

        # Verify copy buttons
        expect(page).to have_css('.api-panel__copy-btn', minimum: 4)
      end
    end
  end

  describe 'reports' do
    it 'displays the API tab with report-specific endpoints and search attributes' do
      report = Report.active.first
      skip 'No active reports found' unless report

      admin_sign_in_with_2fa

      visit '/admin/reports'
      finish_page_loading

      within "#admin-item-#{report.id}" do
        find('a.edit-entity.glyphicon-pencil').click
      end

      # The report form has a different tab structure — the info_block has the API tab
      expect(page).to have_css('.nav-tabs', wait: 10)

      find('.nav-tabs a[aria-controls="api-definitions"]', visible: true).click
      expect(page).to have_css('#api-definitions', visible: true)
      finish_page_loading

      within '#api-definitions' do
        expect(page).to have_css('.api-panel')

        # Verify resource name
        expect(page).to have_content('resource name')
        expect(page).to have_content(report.alt_resource_name)

        # Verify report-specific endpoints (GET only, with format variants)
        expect(page).to have_content('JSON')
        expect(page).to have_content('CSV')
        expect(page).to have_content('Text')
        expect(page).to have_content("/reports/#{report.alt_resource_name}.json")
        expect(page).to have_content("/reports/#{report.alt_resource_name}.csv")
        expect(page).to have_content("/reports/#{report.alt_resource_name}.text")

        # Verify only GET method is shown (reports don't have POST/PUT)
        endpoint_blocks = all('.api-panel__endpoint')
        endpoint_blocks.each do |block|
          expect(block).to have_content('GET')
        end

        # Verify search attributes section
        expect(page).to have_content('url search attributes')
        expect(page).to have_css('.report-item-url-search-attrs')

        # Verify curl examples section
        expect(page).to have_content('curl examples')
        expect(page).to have_css('.api-panel__curl-block', minimum: 2)
        expect(page).to have_content('{{base_url}}')
        expect(page).to have_content('{{app_type_id}}')
        expect(page).to have_content('{{user_email}}')
        expect(page).to have_content('{{api_token}}')

        # Verify save trigger section
        expect(page).to have_content('save trigger usage')
        expect(page).to have_css('.api-panel__save-trigger-block')

        # Verify copy buttons
        expect(page).to have_css('.api-panel__copy-btn', minimum: 4)
      end
    end

    it 'shows a help note in the Definition tab pointing to the API tab' do
      report = Report.active.first
      skip 'No active reports found' unless report

      admin_sign_in_with_2fa

      visit '/admin/reports'
      finish_page_loading

      within "#admin-item-#{report.id}" do
        find('a.edit-entity.glyphicon-pencil').click
      end

      expect(page).to have_css('.nav-tabs', wait: 10)

      # The Definition tab should be active by default
      within '#report-def' do
        expect(page).to have_content('See the API tab')
      end
    end

    it 'displays the use plain attributes label' do
      report = Report.active.first
      skip 'No active reports found' unless report

      admin_sign_in_with_2fa

      visit '/admin/reports'
      finish_page_loading

      within "#admin-item-#{report.id}" do
        find('a.edit-entity.glyphicon-pencil').click
      end

      expect(page).to have_css('.nav-tabs', wait: 10)

      find('.nav-tabs a[aria-controls="api-definitions"]', visible: true).click
      expect(page).to have_css('#api-definitions', visible: true)

      within '#api-definitions' do
        expect(page).to have_content('use plain attributes')
        # The value should be either true or false
        plain_text = find('p', text: 'use plain attributes').text
        expect(plain_text).to match(/true|false/)
      end
    end

    it 'shows search attributes with correct query string format' do
      report = Report.active.first
      skip 'No active reports found' unless report

      admin_sign_in_with_2fa

      visit '/admin/reports'
      finish_page_loading

      within "#admin-item-#{report.id}" do
        find('a.edit-entity.glyphicon-pencil').click
      end

      expect(page).to have_css('.nav-tabs', wait: 10)

      find('.nav-tabs a[aria-controls="api-definitions"]', visible: true).click
      expect(page).to have_css('#api-definitions', visible: true)

      within '#api-definitions' do
        # Search attributes should start with ?
        attrs_el = find('.report-item-url-search-attrs code')
        expect(attrs_el.text).to start_with('?')
        # Should contain either search_attrs[] format or plain format
        expect(attrs_el.text).to match(/search_attrs|=|_report_id_/)
      end
    end
  end

  describe 'copy-to-clipboard handler' do
    it 'fires exactly once even after editing multiple definitions without page navigation' do
      reports = Report.active.limit(2).to_a
      skip 'Need at least 2 active reports' unless reports.length >= 2

      admin_sign_in_with_2fa

      visit '/admin/reports'
      finish_page_loading

      # --- First report: open edit, click API tab, click a copy button ---
      first_report = reports.first
      within "#admin-item-#{first_report.id}" do
        find('a.edit-entity.glyphicon-pencil').click
      end
      expect(page).to have_css('.nav-tabs', wait: 10)

      find('.nav-tabs a[aria-controls="api-definitions"]', visible: true).click
      expect(page).to have_css('#api-definitions', visible: true)
      finish_page_loading

      # Clear any pre-existing flash notices
      page.execute_script("$('.flash .alert').remove()")

      within '#api-definitions' do
        first('.api-panel__copy-btn').click
      end

      # Wait for the flash to appear
      expect(page).to have_css('.flash .alert', wait: 5)
      first_flash_count = all('.flash .alert').count
      expect(first_flash_count).to eq(1), "Expected 1 flash after first copy, got #{first_flash_count}"

      # Clear flashes before the second interaction
      page.execute_script("$('.flash .alert').remove()")
      expect(page).not_to have_css('.flash .alert')

      # --- Second report: open edit, click API tab, click a copy button ---
      second_report = reports.last
      within "#admin-item-#{second_report.id}" do
        find('a.edit-entity.glyphicon-pencil').click
      end
      expect(page).to have_css('.nav-tabs', wait: 10)

      find('.nav-tabs a[aria-controls="api-definitions"]', visible: true).click
      expect(page).to have_css('#api-definitions', visible: true)
      finish_page_loading

      within '#api-definitions' do
        first('.api-panel__copy-btn').click
      end

      # Wait for the flash to appear, then verify exactly one
      expect(page).to have_css('.flash .alert', wait: 5)
      second_flash_count = all('.flash .alert').count
      expect(second_flash_count).to eq(1),
                                    "Expected 1 flash after second copy, got #{second_flash_count} " \
                                    '(duplicate event handler bug)'
    end
  end
end
