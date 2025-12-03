# frozen_string_literal: true

require 'rails_helper'

describe 'admin dynamic model versions', js: true, driver: $browser_driver do
  include ModelSupport

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

    expect(page).to have_selector('.login-2fa-block', visible: true)
    expect(page).to have_selector('#new_admin', visible: true)
    expect(page).to have_selector('input[type="submit"]:not([disabled])', visible: true)

    within '#new_admin' do
      fill_in 'Two-Factor Authentication Code', with: @admin.current_otp
      click_button 'Log in'
    end

    expect(page).to have_css('.flash .alert', text: "×\nSigned in successfully.")
  end

  before(:all) do
    SetupHelper.feature_setup
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    make_an_admin
  end

  it 'creates a dynamic model, makes multiple changes, and displays version diffs' do
    # Create and update a dynamic model programmatically to generate version history
    dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'Test Version Tracking',
      table_name: 'test_version_tracking_recs',
      schema_name: 'dynamic_test',
      category: 'test',
      field_list: 'test_field',
      options: "field_1:\n  label: First Field\n  type: string"
    )
    dm.current_admin = @admin
    dm.update_tracker_events

    # Make updates to create version history
    dm.update!(options: "field_1:\n  label: First Field Updated\n  type: string\nfield_2:\n  label: Second Field\n  type: string")
    dm.update!(options: "field_1:\n  label: First Field Final\n  type: string\n  required: true\nfield_2:\n  label: Second Field Updated\n  type: text\nfield_3:\n  label: Third Field\n  type: number")
    dm.update!(name: 'Test Version Tracking Modified')

    admin_sign_in_with_2fa

    # Navigate to Dynamic Models admin page
    visit '/admin/dynamic_models'

    # Find and click the Edit button (glyphicon) for our dynamic model
    within "#admin-item-#{dm.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    # Wait for the edit form to load via AJAX
    expect(page).to have_css('.nav-tabs', wait: 10)

    # Navigate to the Versions tab (on-open-click JavaScript will auto-trigger Load)
    click_link 'Versions'
    expect(page).to have_css('#def-versions', visible: true)

    # Wait for AJAX to complete and versions to load automatically
    expect(page).to have_css('.version-diff-section', wait: 10)

    # Check for Diffy HTML content (ins/del tags for changes)
    expect(page).to have_css('ins, del', wait: 2)

    # Verify we have multiple version diff sections
    version_sections = all('.version-diff-section')
    expect(version_sections.length).to be >= 3
  end

  it 'shows split diff format for changed fields' do
    # Create a dynamic model programmatically with version history
    dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'Test Split Diff Display2',
      table_name: 'test_version_tracking_recs',
      schema_name: 'dynamic_test',
      category: 'test',
      field_list: 'test_field',
      options: "field_1:\n  label: Original Label"
    )
    dm.current_admin = @admin
    dm.update_tracker_events

    # Update to create a version with changes
    dm.update!(options: "field_1:\n  label: Updated Label\n  type: string")

    admin_sign_in_with_2fa

    # Navigate to Dynamic Models admin page
    visit '/admin/dynamic_models'

    # Wait for the admin list to load
    expect(page).to have_css("#admin-item-#{dm.id}", wait: 10)

    # Find and click the Edit button for our dynamic model
    within "#admin-item-#{dm.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    # Wait for the edit form to load via AJAX
    expect(page).to have_css('.nav-tabs', wait: 15)
    sleep 1 # Extra pause for JS to initialize

    # Navigate to the Versions tab
    within '.nav-tabs' do
      click_link 'Versions'
    end
    expect(page).to have_css('#def-versions', visible: true, wait: 10)

    # Wait for AJAX to load versions automatically
    expect(page).to have_css('.version-diff-section', wait: 10)

    # Verify split diff display structure
    within '#embedded-dynamic-def-versions-embedded' do
      # Should show the Diffy split diff with previous and current columns
      expect(page).to have_css('table.app-import-upload-results tbody tr')

      # Find the Options row (there may be other changed fields too)
      options_row = all('table.app-import-upload-results tbody tr').find do |row|
        row.has_content?(/Options/i)
      end

      expect(options_row).to be_present, 'Expected to find a row with Options field'

      within options_row do
        # Should have 3 columns: field name, previous value, current value
        tds = all('td')
        expect(tds.length).to eq(3)

        # First td should be the field name
        expect(tds[0]).to have_content(/Options/i)

        # Second and third should have Diffy HTML content
        # Diffy adds ul/li elements for line-by-line diffs
        expect(page).to have_css('ul li')
      end
    end
  end

  it 'handles dynamic models with no version history' do
    # Create a dynamic model programmatically with no updates (only 1 version)
    dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'Test No Versions',
      table_name: 'test_version_tracking_recs',
      schema_name: 'dynamic_test',
      category: 'test',
      field_list: 'test_field',
      options: "field_1:\n  label: Single Version Field"
    )
    dm.current_admin = @admin
    dm.update_tracker_events

    # Don't make any updates - only one version should exist

    admin_sign_in_with_2fa

    # Navigate to Dynamic Models admin page
    visit '/admin/dynamic_models'

    # Wait for the admin list to load
    expect(page).to have_css("#admin-item-#{dm.id}", wait: 10)

    # Find and click the Edit button for our dynamic model
    within "#admin-item-#{dm.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    # Wait for the edit form to load via AJAX
    expect(page).to have_css('.nav-tabs', wait: 15)
    sleep 1 # Extra pause for JS to initialize

    # Navigate to the Versions tab
    within '.nav-tabs' do
      click_link 'Versions'
    end
    expect(page).to have_css('#def-versions', visible: true, wait: 10)

    # Wait for AJAX to load versions automatically
    # With only one version, there should be no diffs to display
    sleep 2

    # Should show no version diff sections since there's nothing to compare
    within '#embedded-dynamic-def-versions-embedded' do
      version_sections = all('.version-diff-section')
      # A newly created model with no updates should have no diff sections
      # (no previous version to compare against)
      expect(version_sections.length).to eq(0)
    end
  end
end
