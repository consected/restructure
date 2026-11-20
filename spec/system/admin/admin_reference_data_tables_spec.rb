# frozen_string_literal: true

# Admin reference data tables and views system spec (issue #1567)
#
# Exercises the browser behaviour added to the Tables tab of /admin/reference_data and the
# Table / View panel on dynamic definition admin pages:
# - the schema list is a chosen field that can be filtered by typing
# - the table / view search is a typeahead; choosing a match shows only that table or view, expanded,
#   within its schema, and clearing the search restores the list
# - a view's DDL is shown in a CodeMirror section when the view is expanded, across the full width of its section,
#   below the view's field list
# - the typeahead menu closes once a single table or view match is applied
# - a table's columns that fail to load show a message with a retry link
# - a table that is a dynamic definition links to its admin page in edit mode
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

  it 'shows the chosen schema list and the typeahead table search, and filters the schema list by typing into the chosen field' do
    open_tables_tab

    expect(page).to have_css('.twitter-typeahead #primary_tables_search', visible: :all)

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

  it 'lays out the view definition CodeMirror across the full width of its section, with a limited height' do
    open_tables_tab

    fill_in 'primary_tables_search', with: 'ref_data_sys_view'
    expect(page).to have_css('#tblock-dynamic_test-ref_data_sys_view.in', visible: true, wait: 10)
    find('#tblock-dynamic_test-ref_data_sys_view .ref-view-definition > a').click
    expect(page).to have_css('#tblock-dynamic_test-ref_data_sys_view .ref-view-definition .CodeMirror', visible: true, wait: 10)

    sizes = page.evaluate_script(<<~JS)
      (function () {
        var section = document.querySelector('#tblock-dynamic_test-ref_data_sys_view .ref-view-definition');
        var cm = section.querySelector('.CodeMirror');
        return { section: section.getBoundingClientRect().width, cm: cm.getBoundingClientRect().width,
                 height: cm.getBoundingClientRect().height };
      })()
    JS
    expect(sizes['cm']).to be >= sizes['section'] * 0.95
    expect(sizes['height']).to be_between(60, 500)
  end

  it 'shows the view definition below the field list of the view' do
    open_tables_tab

    fill_in 'primary_tables_search', with: 'ref_data_sys_view'
    expect(page).to have_css('#tblock-dynamic_test-ref_data_sys_view .ref-table-col-item', visible: true, wait: 10)

    below_fields = page.evaluate_script(<<~JS)
      (function () {
        var block = document.getElementById('tblock-dynamic_test-ref_data_sys_view');
        var cols = block.querySelectorAll('.ref-table-col-item');
        var defn = block.querySelector('.ref-view-definition');
        return cols.length > 0 && defn !== null &&
          (cols[cols.length - 1].compareDocumentPosition(defn) & Node.DOCUMENT_POSITION_FOLLOWING) !== 0;
      })()
    JS
    expect(below_fields).to be true
  end

  it 'closes the suggestions menu once a single table or view match is applied' do
    open_tables_tab

    fill_in 'primary_tables_search', with: 'ref_data_sys_'
    expect(page).to have_css('.tt-menu.tt-open', visible: true, wait: 10)

    find('#primary_tables_search').send_keys('base')
    expect(page).to have_css('#tblock-dynamic_test-ref_data_sys_base.in', visible: true, wait: 10)
    expect(page).to have_no_css('.tt-menu.tt-open', visible: true)
  end

  it 'shows a retry message when the columns fail to load, and loads them on retry' do
    open_tables_tab

    page.execute_script(<<~JS)
      window.refDataOrigAjax = $.ajax;
      window.refDataFailColumns = true;
      $.ajax = function (url) {
        if (window.refDataFailColumns && String(url).indexOf('table_list_columns') !== -1) {
          return $.Deferred().reject(null, 'error', 'Server Error').promise();
        }
        return window.refDataOrigAjax.apply(this, arguments);
      };
    JS

    fill_in 'primary_tables_search', with: 'ref_data_sys_base'

    expect(page).to have_css('#tblock-dynamic_test-ref_data_sys_base .ref-tblock__error', visible: true, wait: 10)
    expect(page).to have_no_css('#tblock-dynamic_test-ref_data_sys_base.content-loading')

    page.execute_script('window.refDataFailColumns = false;')
    find('#tblock-dynamic_test-ref_data_sys_base .ref-tblock__retry', visible: true).click

    expect(page).to have_css('#tblock-dynamic_test-ref_data_sys_base .ref-table-col-item', visible: true, wait: 10)
    expect(page).to have_no_css('#tblock-dynamic_test-ref_data_sys_base .ref-tblock__error')
  end

  it 'filters the schema list to the table found by searching, and restores the list when the search is cleared' do
    open_tables_tab

    fill_in 'primary_tables_search', with: 'ref_data_sys_base'

    expect(page).to have_css('#table-list-dynamic_test', visible: true, wait: 10)
    expect(page).to have_css('#tblock-dynamic_test-ref_data_sys_base.in', visible: true, wait: 10)
    expect(page).to have_css('#table-list-dynamic_test .ref-table-item', count: 1, visible: true)
    expect(page).to have_no_css('#t-dynamic_test-ref_data_sys_view', visible: true)

    # Clear the search with keystrokes, as a user would, so the input event is fired
    find('#primary_tables_search').send_keys([:control, 'a'], :backspace)

    expect(page).to have_css('#t-dynamic_test-ref_data_sys_view', visible: true, wait: 10)
    expect(page).to have_css('#t-dynamic_test-ref_data_sys_base', visible: true)
    expect(page).to have_no_css('#tblock-dynamic_test-ref_data_sys_base.in', visible: true, wait: 10)
  end

  it 'links a table that is a dynamic definition to its admin page in edit mode' do
    open_tables_tab

    fill_in 'primary_tables_search', with: 'ref_data_sys_recs'
    within '#table-list-dynamic_test' do
      link = find('#t-dynamic_test-ref_data_sys_recs a.ref-table-definition-link', visible: true)
      expect(link[:title]).to match(/dynamic model/i)
      expect(link[:href]).to include("filter%5Bid%5D=#{@dm.id}")
      expect(link[:href]).to include('perform_action=edit')
    end
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
