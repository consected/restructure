# frozen_string_literal: true

# Tests for the "Referenced by" section in the config library admin details block.
# Verifies that when a config library is referenced by other definitions
# (activity logs, dynamic models, external identifiers, or other config libraries)
# via `# @library category name` in their options, the referencing items
# are displayed with links in the details panel of the admin page.

require 'rails_helper'

describe 'admin config library referenced by', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport

  before(:all) do
    SetupHelper.feature_setup
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    make_an_admin

    @rand_suffix = rand(1_000_000_000)
    @lib_name = "test_refby_lib_#{@rand_suffix}"
    @lib_category = "test_refby_cat_#{@rand_suffix}"

    # Create the config library that will be referenced
    @config_library = Admin::ConfigLibrary.create!(
      current_admin: @admin,
      name: @lib_name,
      category: @lib_category,
      format: 'yaml',
      options: "field_1:\n  label: Test Field"
    )

    # Create another config library that references it
    @referencing_lib = Admin::ConfigLibrary.create!(
      current_admin: @admin,
      name: "test_referencing_#{@rand_suffix}",
      category: @lib_category,
      format: 'yaml',
      options: "some_config:\n  key: value\n# @library #{@lib_category} #{@lib_name}"
    )
  end

  it 'shows the referenced by section with referencing config libraries' do
    admin_sign_in_with_2fa

    visit '/admin/config_libraries'
    finish_page_loading

    # Find and click the Edit button for our config library
    within "#admin-item-#{@config_library.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    # Wait for the edit form to load via AJAX
    expect(page).to have_css('.nav-tabs', wait: 10)

    # Check the Details tab is active and shows Referenced by section
    within '#def-details-block' do
      expect(page).to have_content('Referenced by')
      expect(page).to have_css('.config-library-referenced-by-list')

      within '.config-library-referenced-by-list' do
        expect(page).to have_content("test_referencing_#{@rand_suffix}")
        expect(page).to have_link(href: /config_libraries\?filter/)
      end
    end
  end

  it 'shows links that open in a new tab' do
    admin_sign_in_with_2fa

    visit '/admin/config_libraries'
    finish_page_loading

    within "#admin-item-#{@config_library.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    expect(page).to have_css('.nav-tabs', wait: 10)

    within '#def-details-block' do
      within '.config-library-referenced-by-list' do
        link = find('a', text: /test_referencing_#{@rand_suffix}/)
        expect(link[:target]).to eq('_blank')
      end
    end
  end

  it 'shows a message when not referenced by anything' do
    # Create an unreferenced config library
    unreferenced_lib = Admin::ConfigLibrary.create!(
      current_admin: @admin,
      name: "test_unreferenced_#{@rand_suffix}",
      category: @lib_category,
      format: 'yaml',
      options: "standalone:\n  key: value"
    )

    admin_sign_in_with_2fa

    visit '/admin/config_libraries'
    finish_page_loading

    within "#admin-item-#{unreferenced_lib.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    expect(page).to have_css('.nav-tabs', wait: 10)

    within '#def-details-block' do
      expect(page).to have_content('Not referenced by any definitions')
    end
  end
end
