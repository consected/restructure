# frozen_string_literal: true

# Regression spec for GitHub Issue #1346.
#
# Ensures the admin edit screens for report, external identifier, and message
# template definitions expose a Versions tab, that the tab loads the shared
# history panel with real version-diff content (proving the version tracking
# actually works, not just that the tab exists), and that adding the tab does
# not disrupt each resource's pre-existing tab/panel presentation - notably
# the report admin page's long-standing multi-tab info panel (Definition,
# Data Dictionaries, Tables, ... API), which a naive implementation replaced
# wholesale with a bare Details/Versions panel.

require 'rails_helper'

describe 'admin versions tabs', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport

  before(:all) do
    SetupHelper.feature_setup
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    change_setting('TwoFactorAuthDisabledForUser', true)
    make_an_admin

    @report = Report.create!(
      current_admin: @admin,
      name: "Report Versions Test #{SecureRandom.hex(4)}",
      description: 'Original description',
      sql: 'select 1',
      search_attrs: '',
      disabled: false,
      report_type: 'regular_report',
      auto: false,
      searchable: false
    )
    @report.current_admin = @admin
    @report.update!(description: 'Updated description')

    external_identifier_name = 'versioned_external_identifiers'
    external_id_attribute = 'version_test_ext_id'

    ExternalIdentifier.where(name: external_identifier_name)
                      .or(ExternalIdentifier.where(external_id_attribute: external_id_attribute))
                      .find_each do |record|
      record.current_admin = @admin
      record.disabled = true
      record.save!
    end

    @external_identifier = ExternalIdentifier.create!(
      current_admin: @admin,
      name: external_identifier_name,
      label: 'Versions test external identifier',
      external_id_attribute: external_id_attribute,
      category: 'test',
      min_id: 1,
      max_id: 10,
      alphanumeric: false
    )
    @external_identifier.current_admin = @admin
    @external_identifier.update!(label: 'Versions test external identifier updated')

    @message_template = Admin::MessageTemplate.create!(
      current_admin: @admin,
      name: "message_template_versions_#{SecureRandom.hex(4)}",
      category: 'test',
      message_type: :email,
      template_type: :content,
      template: '<p>Version test</p>'
    )
    @message_template.current_admin = @admin
    @message_template.update!(template: '<p>Version test updated</p>')
  end

  after(:all) do
    @report&.update(disabled: true, current_admin: @admin) if @report&.persisted?
    @external_identifier&.update(disabled: true, current_admin: @admin) if @external_identifier&.persisted?
    @message_template&.update(disabled: true, current_admin: @admin) if @message_template&.persisted?
  end

  before(:each) do
    admin_sign_in_with_2fa
  end

  # Opens the edit form for a record, switches to a Versions tab scoped to
  # `nav_tabs_selector` (each resource wraps its tabs in a different
  # pre-existing container - see class comment), and waits for the version
  # history to actually load (proving real diff content, not just tab markup).
  def expect_versions_tab_with_diff(path:, record_id:, nav_tabs_selector:, embedded_container_id: 'embedded-dynamic-def-versions-embedded')
    visit path
    finish_page_loading

    within "#admin-item-#{record_id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    expect(page).to have_css(nav_tabs_selector, wait: 10)
    within nav_tabs_selector do
      click_link 'Versions'
    end

    expect(page).to have_css('#def-versions, #def-versions-embedded', visible: true, wait: 10)
    expect(page).to have_css("##{embedded_container_id} .version-diff-section", wait: 10)
    expect(page).to have_css("##{embedded_container_id} ins, ##{embedded_container_id} del", wait: 2)
  end

  it 'shows a working Versions tab on the report admin page without disturbing the existing info tabs' do
    expect_versions_tab_with_diff(
      path: '/admin/reports',
      record_id: @report.id,
      nav_tabs_selector: '.admin-options-block-outer .nav-tabs'
    )

    # The report's original multi-tab info panel (issue: previously destroyed
    # by wrapping it in a full-width block below a competing tab set) must
    # still be present alongside the new Versions tab.
    within '.admin-options-block-outer .nav-tabs' do
      %w[Definition Tables Flags].each { |label| expect(page).to have_content(label) }
    end
  end

  it 'shows a working Versions tab on the external identifier admin page' do
    expect_versions_tab_with_diff(
      path: '/admin/external_identifiers',
      record_id: @external_identifier.id,
      nav_tabs_selector: '.admin-options-ref-block .nav-tabs'
    )
  end

  it 'shows a working Versions tab on the message template admin page' do
    expect_versions_tab_with_diff(
      path: '/admin/message_templates',
      record_id: @message_template.id,
      nav_tabs_selector: '.admin-options-ref-block .nav-tabs'
    )
  end
end
