# frozen_string_literal: true

require 'rails_helper'

describe 'admin config library versions', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup

  before(:all) do
    SetupHelper.feature_setup
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    make_an_admin
  end

  def format_version_timestamp_for(config_library, which)
    rows = config_library.all_versions_query(limit: 2)
    row = which == :current ? rows.first : rows.second
    Object.new.extend(CommonTemplatesHelper).format_version_timestamp(row['updated_at'] || row['created_at'])
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

    # Each heading should show real timestamps, not "Unknown" (issue: history
    # rows return real Time objects, and Time.parse(a_time) always raised,
    # silently rescued to the literal string "Unknown")
    version_sections.each do |section|
      expect(section).to have_css('h4 small', text: /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
      expect(section).not_to have_content('Unknown')
    end
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

  it 'shows the heading timestamp order matching the table column order (Previous -> Current), and excludes updated_at/created_at as a diffed row' do
    cl = Admin::ConfigLibrary.create!(
      current_admin: @admin,
      name: 'test_heading_order_library',
      category: 'test',
      format: 'yaml',
      options: "field_1:\n  label: Original Label"
    )

    cl.current_admin = @admin
    cl.update!(options: "field_1:\n  label: Updated Label")

    admin_sign_in_with_2fa

    visit '/admin/config_libraries'
    expect(page).to have_css("#admin-item-#{cl.id}", wait: 10)

    within "#admin-item-#{cl.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    expect(page).to have_css('.nav-tabs', wait: 15)
    sleep 1

    within '.nav-tabs' do
      click_link 'Versions'
    end
    expect(page).to have_css('#def-versions-embedded', visible: true, wait: 10)
    expect(page).to have_css('.version-diff-section', wait: 10)

    within '#embedded-config-library-def-versions-embedded .version-diff-section' do
      # The table's "Previous Version" header column comes before "Current
      # Version" - the heading's two timestamps must be in the same order.
      # (thead also contains the id/created_at/updated_at identifier rows, so
      # scope to just the first header row for the column labels.)
      header_cells = all('thead tr').first.all('th').map(&:text)
      expect(header_cells).to eq(['Attribute', 'Previous Version', 'Current Version'])

      heading_text = find('h4').text
      timestamps = heading_text.scan(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
      expect(timestamps.length).to eq(2)

      previous_updated_at = format_version_timestamp_for(cl, :previous)
      current_updated_at = format_version_timestamp_for(cl, :current)
      expect(timestamps).to eq([previous_updated_at, current_updated_at])

      # updated_at/created_at are shown in the header row above, not repeated
      # as a diffed row in the changes table body.
      body_row_labels = all('tbody tr td strong').map(&:text)
      expect(body_row_labels).not_to include('Updated At')
      expect(body_row_labels).not_to include('Created At')
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

  it 'shows the total version count and a truncation note when history exceeds the display limit' do
    stub_const('Dynamic::VersionHandler::MAX_DISPLAYED_VERSIONS', 3)

    cl = Admin::ConfigLibrary.create!(
      current_admin: @admin,
      name: 'test_version_count_library',
      category: 'test',
      format: 'yaml',
      options: "field_1:\n  label: First Field"
    )

    # Insert extra history rows directly so the total exceeds the display limit
    # without needing many slow real updates.
    5.times do |i|
      Admin::MigrationGenerator.connection.execute <<~SQL
        insert into config_library_history (config_library_id, name, category, format, created_at, updated_at)
        values (
          #{cl.id},
          'test_version_count_library',
          'test',
          'yaml',
          now() - interval '#{5 - i} minutes',
          now() - interval '#{5 - i} minutes'
        )
      SQL
    end

    admin_sign_in_with_2fa

    visit '/admin/config_libraries'
    expect(page).to have_css("#admin-item-#{cl.id}", wait: 10)

    within "#admin-item-#{cl.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    expect(page).to have_css('.nav-tabs', wait: 15)
    sleep 1

    within '.nav-tabs' do
      click_link 'Versions'
    end
    expect(page).to have_css('#def-versions-embedded', visible: true, wait: 10)

    within '#embedded-config-library-def-versions-embedded' do
      expect(page).to have_css('.admin-version__count', text: '6 versions', wait: 10)
      expect(page).to have_content('most recent 3 versions shown')
    end
  end

  it 'loads more versions when the "load more" link is clicked' do
    stub_const('Dynamic::VersionHandler::MAX_DISPLAYED_VERSIONS', 3)

    cl = Admin::ConfigLibrary.create!(
      current_admin: @admin,
      name: 'test_load_more_library',
      category: 'test',
      format: 'yaml',
      options: "field_1:\n  label: First Field"
    )

    5.times do |i|
      Admin::MigrationGenerator.connection.execute <<~SQL
        insert into config_library_history (config_library_id, name, category, format, options, created_at, updated_at)
        values (
          #{cl.id},
          'test_load_more_library',
          'test',
          'yaml',
          'field_1:#{"\n  label: Version #{i}"}',
          now() - interval '#{5 - i} minutes',
          now() - interval '#{5 - i} minutes'
        )
      SQL
    end

    admin_sign_in_with_2fa

    visit '/admin/config_libraries'
    expect(page).to have_css("#admin-item-#{cl.id}", wait: 10)

    within "#admin-item-#{cl.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    expect(page).to have_css('.nav-tabs', wait: 15)
    sleep 1

    within '.nav-tabs' do
      click_link 'Versions'
    end
    expect(page).to have_css('#def-versions-embedded', visible: true, wait: 10)

    within '#embedded-config-library-def-versions-embedded' do
      expect(page).to have_css('.admin-version__count', text: '6 versions', wait: 10)
      expect(page).to have_content('most recent 3 versions shown')
      initial_section_count = all('.version-diff-section').length

      click_link 'Load 3 more versions'

      expect(page).to have_css('.admin-version__count', text: '6 versions', wait: 10)
      expect(page).not_to have_content('most recent')
      expect(all('.version-diff-section').length).to be > initial_section_count
      expect(page).not_to have_link('Load')
    end
  end
end
