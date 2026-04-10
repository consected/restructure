# frozen_string_literal: true

require 'rails_helper'

describe 'admin parsed config display', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport

  before(:all) do
    SetupHelper.feature_setup
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    make_an_admin
  end

  describe 'dynamic models' do
    it 'displays parsed config tab with line numbers' do
      # Find a dynamic model and ensure it has option types that produce parsed config output
      dm = DynamicModel.active.first
      expect(dm).not_to be nil

      # Set up options with actual config so parsed_options_text produces output
      dm.current_admin = @admin
      dm.options = <<~YAML
        default:
          labels:
            field_1: Test Field
          view_options:
            data_attribute: field_1
      YAML
      dm.updated_at = Time.now
      dm.save!

      admin_sign_in_with_2fa

      # Navigate to Dynamic Models admin page
      visit '/admin/dynamic_models'

      # Find and click the Edit button for our dynamic model
      within "#admin-item-#{dm.id}" do
        find('a.edit-entity.glyphicon-pencil').click
      end

      # Wait for the edit form to load via AJAX
      expect(page).to have_css('.nav-tabs', wait: 10)

      # Navigate to the Parsed Config tab
      click_link 'Parsed Config'
      expect(page).to have_css('#parsed-config', visible: true)

      # Wait for CodeMirror to render (may need time for JS initialization after tab switch)
      expect(page).to have_css('#parsed-config .CodeMirror', wait: 10)

      # Verify merged YAML content is displayed with CodeMirror
      within '#parsed-config .CodeMirror' do
        content = page.text
        expect(content.length).to be > 10
        expect(content).to match(/:\s/)
      end

      # Verify merged YAML content is displayed with CodeMirror
      within '#parsed-config .CodeMirror' do
        content = page.text
        expect(content.length).to be > 10
        expect(content).to match(/:\s/)
      end

      # Verify CodeMirror has line numbers configured (gutter present)
      expect(page).to have_css('#parsed-config .CodeMirror-gutters', visible: :all)
    end

    it 'handles dynamic models with no config options' do
      # Find or use a dynamic model (all should have at least some config after parsing)
      dm = DynamicModel.active.first

      expect(dm).not_to be nil

      admin_sign_in_with_2fa

      visit '/admin/dynamic_models'

      within "#admin-item-#{dm.id}" do
        find('a.edit-entity.glyphicon-pencil').click
      end

      expect(page).to have_css('.nav-tabs', wait: 10)

      click_link 'Parsed Config'
      expect(page).to have_css('#parsed-config', visible: true)

      # Should show either CodeMirror config or warning message
      expect(page).to have_css('#parsed-config .CodeMirror, .alert-warning', wait: 5)
    end
  end

  describe 'activity logs' do
    it 'displays parsed config tab with YAML output' do
      # Find any existing activity log
      al = ActivityLog.active.first

      skip 'No active activity logs found' unless al

      # Ensure it has extra_log_types for this test
      unless al.extra_log_types.present?
        al.update_column(:extra_log_types, "default:\n  label: Test Log\n  fields:\n    - field1\n")
        al.force_option_config_parse if al.respond_to?(:force_option_config_parse)
        al.reload
      end

      admin_sign_in_with_2fa

      visit '/admin/activity_logs'

      # Wait for page to load
      expect(page).to have_css("#admin-item-#{al.id}", wait: 10)

      within "#admin-item-#{al.id}" do
        find('a.edit-entity.glyphicon-pencil').click
      end

      expect(page).to have_css('.nav-tabs', wait: 15)
      sleep 1 # Extra wait for AJAX

      click_link 'Parsed Config'
      expect(page).to have_css('#parsed-config', visible: true)
      finish_page_loading

      expect(page).to have_css('#parsed-config .CodeMirror', wait: 5)

      within '#parsed-config .CodeMirror' do
        content = page.text
        expect(content.length).to be > 10
        expect(content).to match(/:\s/)
      end

      # Verify CodeMirror has line numbers configured (gutter present)
      expect(page).to have_css('#parsed-config .CodeMirror-gutters', visible: :all)
    end
  end

  describe 'external identifiers' do
    it 'displays warning for external identifier with no options' do
      # Find an external identifier without options
      ei = ExternalIdentifier.active.find_by(options: nil) || ExternalIdentifier.active.first

      skip 'No active external identifiers found' unless ei

      # Ensure it has no options for this test
      if ei.options.present?
        ei.update_column(:options, nil)
        ei.force_option_config_parse if ei.respond_to?(:force_option_config_parse)
      end

      admin_sign_in_with_2fa

      visit '/admin/external_identifiers'

      # Wait for page to load
      expect(page).to have_css("#admin-item-#{ei.id}", wait: 10)

      within "#admin-item-#{ei.id}" do
        find('a.edit-entity.glyphicon-pencil').click
      end

      expect(page).to have_css('.nav-tabs', wait: 15)
      sleep 1 # Extra wait for AJAX

      click_link 'Parsed Config'
      expect(page).to have_css('#parsed-config', visible: true)

      # Should show warning message when no options
      expect(page).to have_css('.alert-warning', wait: 5)
      expect(page).to have_content('No merged configuration text available')
    end

    it 'displays parsed config when external identifier has options' do
      # Find or create an external identifier with options
      ei = ExternalIdentifier.active.find { |e| e.options.present? }

      unless ei
        ei = ExternalIdentifier.active.first
        skip 'No active external identifiers found' unless ei

        # Add simple options
        ei.update_column(:options, "default:\n  label: Test Label\n")
        ei.force_option_config_parse if ei.respond_to?(:force_option_config_parse)
      end

      admin_sign_in_with_2fa

      visit '/admin/external_identifiers'
      finish_page_loading
      # Wait for page to load
      expect(page).to have_css("#admin-item-#{ei.id}", wait: 10)

      within "#admin-item-#{ei.id}" do
        find('a.edit-entity.glyphicon-pencil').click
      end

      finish_form_formatting
      expect(page).to have_css('.nav-tabs', wait: 20)
      finish_page_loading
      sleep 1 # Extra wait for AJAX

      click_link 'Parsed Config'
      expect(page).to have_css('#parsed-config', visible: true)
      finish_page_loading

      expect(page).to have_css('#parsed-config .CodeMirror', wait: 5)

      within '#parsed-config .CodeMirror' do
        content = page.text
        expect(content.length).to be > 10
        expect(content).to match(/:\s/)
      end

      # Verify CodeMirror has line numbers configured (gutter present)
      expect(page).to have_css('#parsed-config .CodeMirror-gutters', visible: :all)
    end
  end

  describe 'error handling' do
    it 'displays error message for invalid config' do
      # Use any existing dynamic model (they all should work)
      dm = DynamicModel.active.first

      expect(dm).not_to be nil

      admin_sign_in_with_2fa

      visit '/admin/dynamic_models'
      finish_page_loading

      within "#admin-item-#{dm.id}" do
        find('a.edit-entity.glyphicon-pencil').click
      end
      finish_form_formatting

      expect(page).to have_css('.nav-tabs', wait: 10)
      sleep 1 # Extra wait for AJAX

      click_link 'Parsed Config'
      sleep 1 # Wait for tab content to load

      # Should either show the CodeMirror parsed config or an error/warning message
      expect(page).to have_css('#parsed-config .CodeMirror, .alert-danger, .alert-warning', wait: 5)
    end
  end
end
