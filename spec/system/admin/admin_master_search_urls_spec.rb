# frozen_string_literal: true

# System tests for Master Records admin page showing URL search formats (issue #1041)
#
# Tests that verify the Master Records admin page displays URL formats for
# various search methods in the URL Search tab, and that each external
# identifier's details panel shows the URL search format for that external identifier.

require 'rails_helper'

describe 'Master Records admin URL search formats', js: true, driver: $browser_driver do
  include ModelSupport
  include FeatureSupport
  include UserSupport

  before(:all) do
    SetupHelper.feature_setup

    change_setting('TwoFactorAuthDisabledForAdmin', true)

    create_admin
    @admin.update!(capabilities: %w[master_records external_identifiers])

    @user, = create_user
    @master = Master.create!(current_user: @user)
    change_setting('AdminMaster', @master.id)
  end

  before(:each) do
    login_as(@admin, scope: :admin)
  end

  after(:all) do
    change_setting('TwoFactorAuthDisabledForAdmin', false)
  end

  def open_masters_url_search_tab
    visit '/admin/master_records'

    within('.master-records-index__models-table tbody') do
      first('a.glyphicon-eye-open').click
    end

    expect(page).to have_css('.master-records-show-panel', wait: 10)
    click_link 'URL Search'
    expect(page).to have_css('.master-records-url-search-formats', wait: 10)
  end

  describe 'URL Search tab' do
    it 'shows URL search formats section' do
      open_masters_url_search_tab

      expect(page).to have_content('URL search formats')
    end

    it 'shows the direct master ID URL format' do
      open_masters_url_search_tab

      expect(page).to have_content('/masters/<master_id>')
    end

    it 'shows crosswalk attribute URL format' do
      open_masters_url_search_tab

      expect(page).to have_content('/masters/<value>?type=<crosswalk_attr>')
    end

    it 'shows external ID URL format' do
      open_masters_url_search_tab

      expect(page).to have_content('/masters/<value>?type=<external_id_attr>')
    end

    it 'shows search with external_id params URL format' do
      open_masters_url_search_tab

      expect(page).to have_content('external_id[field]')
      expect(page).to have_content('external_id[id]')
    end

    it 'lists the available crosswalk attributes in a table' do
      open_masters_url_search_tab

      crosswalk_attrs = Master.crosswalk_attrs
      expect(crosswalk_attrs).not_to be_empty

      crosswalk_attrs.each do |attr|
        expect(page).to have_content(attr.to_s)
      end
    end

    it 'lists available external identifiers with links' do
      open_masters_url_search_tab

      ext_defs = Master.external_id_definitions
      next if ext_defs.empty?

      ext_defs.each do |attr_name, ext_id|
        expect(page).to have_content(attr_name.to_s)
        expect(page).to have_content(ext_id.label)
        expected_path = admin_external_identifiers_path(filter: { name: ext_id.name, disabled: :enabled }, perform_action: 'edit')
        expect(page).to have_link(attr_name.to_s, href: expected_path)
      end
    end
  end

  describe 'External identifier details panel' do
    it 'shows the URL search format for the external identifier' do
      visit '/admin/external_identifiers'

      first('.admin-list-item:not(.disabled-result) .simple-admin-edit').click

      expect(page).to have_css('.dynamic-details-section', wait: 10)

      expect(page).to have_content('URL search format')
    end

    it 'shows the correct URL with the external id attribute name' do
      visit '/admin/external_identifiers'

      first('.admin-list-item:not(.disabled-result) .simple-admin-edit').click

      expect(page).to have_css('.dynamic-details-section', wait: 10)

      attr_name = find('.dynamic-details-section').text[%r{/masters/<value>\?type=(\w+)}, 1]
      expect(attr_name).to be_present
      expect(page).to have_content("/masters/<value>?type=#{attr_name}")
    end
  end
end
