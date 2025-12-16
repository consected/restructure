# frozen_string_literal: true

require 'rails_helper'

describe 'admin config library versions', js: true, driver: $browser_driver do
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

  it 'creates a config library, makes multiple changes, and displays version diffs' do
    # Create and update a config library programmatically to generate version history
    cl = Admin::ConfigLibrary.create!(
      current_admin: @admin,
      name: 'test_version_library',
      category: 'test',
      format: 'yaml',
      options: "field_1:\n  label: First Field\n  type: string"
    )

    # Make updates to create version history
    cl.current_admin = @admin
    cl.update!(options: "field_1:\n  label: First Field Updated\n  type: string\nfield_2:\n  label: Second Field\n  type: string")
    cl.update!(options: "field_1:\n  label: First Field Final\n  type: string\n  required: true\nfield_2:\n  label: Second Field Updated\n  type: text\nfield_3:\n  label: Third Field\n  type: number")
    cl.update!(name: 'test_version_library_modified')

    admin_sign_in_with_2fa

    # Navigate to Config Libraries admin page
    visit '/admin/config_libraries'

    # Find and click the Edit button (glyphicon) for our config library
    within "#admin-item-#{cl.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    # Wait for the edit form to load via AJAX
    expect(page).to have_css('.nav-tabs', wait: 10)

    # Navigate to the Versions tab (on-open-click will auto-trigger Load)
    click_link 'Versions'
    expect(page).to have_css('#def-versions-embedded', visible: true)

    # Wait for AJAX to complete and versions to load automatically
    expect(page).to have_css('.version-diff-section', wait: 10)

    # Check for Diffy HTML content (ins/del tags for changes)
    expect(page).to have_css('ins, del', wait: 2)

    # Verify we have multiple version diff sections
    version_sections = all('.version-diff-section')
    expect(version_sections.length).to be >= 3
  end

  it 'shows split diff format for changed fields' do
    # Create a config library programmatically with version history
    cl = Admin::ConfigLibrary.create!(
      current_admin: @admin,
      name: 'test_split_diff_library',
      category: 'test',
      format: 'yaml',
      options: "field_1:\n  label: Original Label"
    )

    # Update to create a version with changes
    cl.current_admin = @admin
    cl.update!(options: "field_1:\n  label: Updated Label\n  type: string")

    admin_sign_in_with_2fa

    # Navigate to Config Libraries admin page
    visit '/admin/config_libraries'

    # Wait for the admin list to load
    expect(page).to have_css("#admin-item-#{cl.id}", wait: 10)

    # Find and click the Edit button for our config library
    within "#admin-item-#{cl.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    # Wait for the edit form to load via AJAX
    expect(page).to have_css('.nav-tabs', wait: 15)
    sleep 1 # Extra pause for JS to initialize

    # Navigate to the Versions tab
    within '.nav-tabs' do
      click_link 'Versions'
    end
    expect(page).to have_css('#def-versions-embedded', visible: true, wait: 10)

    # Wait for AJAX to load versions automatically (on-open-click triggers Load)
    expect(page).to have_css('.version-diff-section', wait: 10)

    # Verify split diff display structure
    within '#embedded-config-library-def-versions-embedded' do
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

  it 'handles config libraries with no version history' do
    # Create a config library programmatically with no updates (only 1 version)
    cl = Admin::ConfigLibrary.create!(
      current_admin: @admin,
      name: 'test_no_versions_library',
      category: 'test',
      format: 'yaml',
      options: "field_1:\n  label: Single Version Field"
    )

    # Don't make any updates - only one version should exist

    admin_sign_in_with_2fa

    # Navigate to Config Libraries admin page
    visit '/admin/config_libraries'

    # Wait for the admin list to load
    expect(page).to have_css("#admin-item-#{cl.id}", wait: 10)

    # Find and click the Edit button for our config library
    within "#admin-item-#{cl.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    # Wait for the edit form to load via AJAX
    expect(page).to have_css('.nav-tabs', wait: 15)
    sleep 1 # Extra pause for JS to initialize

    # Navigate to the Versions tab
    within '.nav-tabs' do
      click_link 'Versions'
    end
    expect(page).to have_css('#def-versions-embedded', visible: true, wait: 10)

    # Wait for AJAX to load versions automatically
    # With only one version, there should be no diffs to display
    sleep 2

    # Should show no version diff sections since there's nothing to compare
    within '#embedded-config-library-def-versions-embedded' do
      version_sections = all('.version-diff-section')
      # A newly created config library with no updates should have no diff sections
      # (no previous version to compare against)
      expect(version_sections.length).to eq(0)
    end
  end
end
