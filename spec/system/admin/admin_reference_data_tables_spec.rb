# frozen_string_literal: true

# Admin reference data tables and views system spec (issue #1567)
#
# Exercises the browser behaviour added to the Tables tab of /admin/reference_data and the
# Table / View panel on dynamic definition admin pages:
# - the schema list is a chosen field that can be filtered by typing
# - a view's DDL is shown in a CodeMirror section when the view is expanded
# - searching for a table or view name without its schema expands it automatically when one matches
# - a dynamic definition's Table / View panel shows its own table columns

require 'rails_helper'

describe 'admin reference data tables and views', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport

  before(:all) do
    SetupHelper.feature_setup
    create_admin
    create_user
    ENV['FPHS_ADMIN_SETUP'] = 'yes'
    make_an_admin

    ActiveRecord::Base.connection.execute <<~SQL
      DROP VIEW IF EXISTS dynamic_test.ref_data_sys_view;
      DROP TABLE IF EXISTS dynamic_test.ref_data_sys_base;
      CREATE TABLE dynamic_test.ref_data_sys_base (id integer PRIMARY KEY, label varchar);
      CREATE VIEW dynamic_test.ref_data_sys_view AS SELECT id, label FROM dynamic_test.ref_data_sys_base;
    SQL
    Admin::MigrationGenerator.tables_and_views_reset!

    DynamicModel.active.where(table_name: 'ref_data_sys_recs').each { |dm| dm.disable!(@admin) }
    @dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'Ref Data Sys Recs',
      schema_name: 'dynamic_test',
      table_name: 'ref_data_sys_recs',
      category: :details,
      field_list: 'description',
      primary_key_name: 'id',
      foreign_key_name: 'master_id'
    )
  end

  after(:all) do
    DynamicModel.active.where(table_name: 'ref_data_sys_recs').each { |dm| dm.disable!(@admin) }
    ActiveRecord::Base.connection.execute <<~SQL
      DROP VIEW IF EXISTS dynamic_test.ref_data_sys_view;
      DROP TABLE IF EXISTS dynamic_test.ref_data_sys_base;
    SQL
    Admin::MigrationGenerator.tables_and_views_reset!
  end

  def open_tables_tab
    admin_sign_in_with_2fa
    visit '/admin/reference_data'
    finish_page_loading
    find('.nav-tabs a[aria-controls="tables"]', visible: true).click
    expect(page).to have_css('#primary_tables_schema_select', visible: :all, wait: 10)
  end

  it 'filters the schema list by typing into the chosen field, and shows a view definition' do
    open_tables_tab

    # The chosen dropdown is positioned at body level, so it is outside the tables block
    find('#primary_tables_schema_select_chosen a.chosen-single', visible: true).click
    drop = 'body > .chosen-container.chosen-with-drop'
    find("#{drop} .chosen-search input", visible: true).set('dynamic_test')
    find("#{drop} .chosen-results li", text: 'dynamic_test', visible: true).click

    expect(page).to have_css('#table-list-dynamic_test', visible: true, wait: 10)
    within '#table-list-dynamic_test' do
      expect(page).to have_css('#t-dynamic_test-ref_data_sys_view', wait: 10)
      expect(page).to have_css('#t-dynamic_test-ref_data_sys_view[data-object-type="view"]', visible: :all)
      find('#t-dynamic_test-ref_data_sys_view a.table-name-collapser').click
      find('#tblock-dynamic_test-ref_data_sys_view .ref-view-definition > a').click
    end

    expect(page).to have_css('#tblock-dynamic_test-ref_data_sys_view .ref-view-definition .CodeMirror', visible: true, wait: 10)
    expect(page).to have_css('#tblock-dynamic_test-ref_data_sys_view .CodeMirror', text: 'ref_data_sys_base', visible: true)
  end

  it 'expands a table found by searching for its name without the schema' do
    open_tables_tab

    fill_in 'primary_tables_search', with: 'ref_data_sys_base'

    expect(page).to have_css('#tblock-dynamic_test-ref_data_sys_base.in', visible: true, wait: 10)
  end

  it 'shows the Table / View panel for a dynamic definition with its own table columns' do
    admin_sign_in_with_2fa
    visit '/admin/dynamic_models'
    finish_page_loading

    within "#admin-item-#{@dm.id}" do
      find('a.edit-entity.glyphicon-pencil').click
    end

    expect(page).to have_css('.nav-tabs', wait: 10)
    find('.nav-tabs a[aria-controls="dm-table-view"]', visible: true).click

    within '#dm-table-view' do
      expect(page).to have_css('#dm-table-view-panel', visible: true)
      expect(page).to have_content('ref_data_sys_recs')
      expect(page).to have_css('.ref-table-col-item', text: 'description', wait: 10)
    end
  end
end
