# frozen_string_literal: true

# Regression spec: admin version-diff panel must show one diff section per
# consecutive pair of loaded versions, even when a pair has no changes in the
# tracked fields (a duplicate/no-op history row - e.g. from a `touch` or a
# re-save that didn't alter any tracked attribute).
#
# Previously `calculate_version_diffs` silently dropped any pair with no
# attribute changes, so the "N versions" count shown to the admin no longer
# matched the number of version-diff-section blocks rendered - e.g. for
# ExternalIdentifier id 3 (bhs_assignments) in production data: 21 versions
# but only 6 diff sections displayed, with no indication that 14 versions had
# been silently hidden.

require 'rails_helper'

describe 'admin version diff count matches version count', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup

  before(:all) do
    SetupHelper.feature_setup
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    make_an_admin
  end

  it 'renders a diff section (with a "no changes" notice) for a no-op version, not just for versions with real changes' do
    cl = Admin::ConfigLibrary.create!(
      current_admin: @admin,
      name: "test_no_op_version_lib_#{SecureRandom.hex(4)}",
      category: 'test',
      format: 'yaml',
      options: "field_1:\n  label: First Field"
    )

    # A no-op update: touches updated_at (tracked as a header identifier, not
    # a diffed field) but changes no other tracked attribute - this is what
    # produces a "version" with an empty changes hash.
    cl.touch

    # A real change afterwards, so both empty and non-empty diffs are present.
    cl.current_admin = @admin
    cl.update!(options: "field_1:\n  label: First Field Updated")

    expect(cl.all_versions_count).to eq(3)

    admin_sign_in_with_2fa

    visit '/admin/config_libraries'
    expect(page).to have_css("#admin-item-#{cl.id}", wait: 10)

    within "#admin-item-#{cl.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    expect(page).to have_css('.nav-tabs', wait: 15)
    within '.nav-tabs' do
      click_link 'Versions'
    end
    expect(page).to have_css('#def-versions-embedded', visible: true, wait: 10)

    # 3 versions -> 2 consecutive pairs -> 2 diff sections, regardless of
    # whether a given pair has real attribute changes.
    expect(page).to have_css('.version-diff-section', count: 2, wait: 10)

    within all('.version-diff-section').last do
      expect(page).to have_content('No changes')
    end
  ensure
    cl&.update(disabled: true, current_admin: @admin) if cl&.persisted?
  end
end
