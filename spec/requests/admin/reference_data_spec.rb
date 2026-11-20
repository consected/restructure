# frozen_string_literal: true

# Admin reference data tables and views request spec (issue #1567)
#
# Covers the endpoints behind the Tables tab of /admin/reference_data, and the Table / View
# panel shown on dynamic definition admin pages:
# - the schema list is a "chosen" select, with a table / view search field beside it
# - each table or view is labelled as a table or a view
# - a view shows its DDL (pg_get_viewdef) in a CodeMirror section
# - a table or view that is a dynamic definition links to its admin page using filter[id]
# - the columns endpoint refuses names that are not visible to the app

require 'rails_helper'

RSpec.describe 'Admin reference data tables and views', type: :request do
  include ModelSupport

  before(:all) do
    @prev_allow_dms = Settings::AllowDynamicMigrations
    change_setting('AllowDynamicMigrations', true)

    create_admin
    ActiveRecord::Base.connection.execute <<~SQL
      DROP VIEW IF EXISTS dynamic_test.ref_data_spec_view;
      DROP TABLE IF EXISTS dynamic_test.ref_data_spec_base;
      CREATE TABLE dynamic_test.ref_data_spec_base (id integer PRIMARY KEY, label varchar);
      CREATE VIEW dynamic_test.ref_data_spec_view AS SELECT id, label FROM dynamic_test.ref_data_spec_base;
    SQL

    DynamicModel.active.where(table_name: 'ref_data_spec_recs').each { |dm| dm.disable!(@admin) }
    @dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'Ref Data Spec Recs',
      schema_name: 'dynamic_test',
      table_name: 'ref_data_spec_recs',
      category: :details,
      field_list: 'description',
      primary_key_name: 'id',
      foreign_key_name: 'master_id'
    )
    Admin::MigrationGenerator.tables_and_views_reset!
    @ei = ExternalIdentifier.create!(
      current_admin: @admin,
      name: 'ref_data_spec_eis',
      label: 'Ref data spec EI',
      external_id_attribute: 'ref_data_spec_ext_id',
      min_id: 1,
      max_id: 99_999_999,
      schema_name: 'dynamic_test',
      category: :test
    )
    @al = ActivityLog.create!(
      current_admin: @admin,
      name: 'ref_data_spec_als',
      item_type: 'player_contact',
      process_name: 'refdataspecals',
      schema_name: 'dynamic_test',
      category: :test,
      action_when_attribute: 'created_at',
      extra_log_types: <<~YAML
        step_ref_data:
          label: Ref data spec
          fields:
            - data
      YAML
    )
    Admin::MigrationGenerator.tables_and_views_reset!
  end

  after(:all) do
    DynamicModel.active.where(table_name: 'ref_data_spec_recs').each { |dm| dm.disable!(@admin) }
    [@ei, @al].each { |definition| definition&.disable!(@admin) }
    ActiveRecord::Base.connection.execute <<~SQL
      DROP VIEW IF EXISTS dynamic_test.ref_data_spec_view;
      DROP TABLE IF EXISTS dynamic_test.ref_data_spec_base;
    SQL
    Admin::MigrationGenerator.tables_and_views_reset!
    change_setting('AllowDynamicMigrations', @prev_allow_dms)
  end

  before { sign_in @admin }

  # The table / view search items, as embedded in the data-search-items attribute of the search field
  def search_items
    JSON.parse(Nokogiri::HTML(response.body).at_css('#primary_tables_search')['data-search-items'])
  end

  # The definition link for a table in the dynamic_test schema list, if any
  def definition_link(table_name)
    Nokogiri::HTML(response.body).at_css("#t-dynamic_test-#{table_name} a.ref-table-definition-link")
  end

  describe 'GET /admin/reference_data/table_list' do
    before { get '/admin/reference_data/table_list' }

    it 'renders the schema select as a chosen field' do
      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/<select[^>]*id="primary_tables_schema_select"[^>]*use-chosen/)
    end

    it 'renders a table / view search field as a typeahead beside the schema select' do
      expect(response.body).to match(/<input[^>]*id="primary_tables_search"[^>]*class="[^"]*typeahead/)
      expect(response.body).not_to include('primary_tables_search_options')
    end

    it 'lists tables and views in the search items, without needing the schema' do
      expect(search_items).to include(hash_including('label' => 'dynamic_test.ref_data_spec_view',
                                                     'object_type' => 'view'))
    end
  end

  describe 'GET /admin/reference_data/table_list_tables' do
    before { get '/admin/reference_data/table_list_tables', params: { schema_name: 'dynamic_test' } }

    it 'labels a view as a view and a table as a table' do
      expect(response.body).to match(/id="t-dynamic_test-ref_data_spec_view"[^>]*data-object-type="view"/)
      expect(response.body).to match(/id="t-dynamic_test-ref_data_spec_base"[^>]*data-object-type="table"/)
    end

    it 'links a dynamic model table to its admin page in edit mode' do
      link = definition_link('ref_data_spec_recs')
      expect(link['href']).to eq admin_dynamic_models_path(filter: { id: @dm.id }, perform_action: 'edit')
      expect(link['title'].downcase).to include('dynamic model')
    end

    it 'links an activity log table to its admin page in edit mode' do
      link = definition_link(@al.table_name)
      expect(link['href']).to eq admin_activity_logs_path(filter: { id: @al.id }, perform_action: 'edit')
      expect(link['title'].downcase).to include('activity log')
    end

    it 'links an external identifier table to its admin page in edit mode' do
      link = definition_link(@ei.table_name)
      expect(link['href']).to eq admin_external_identifiers_path(filter: { id: @ei.id }, perform_action: 'edit')
      expect(link['title'].downcase).to include('external identifier')
    end

    it 'does not link a table or view that is not a dynamic definition' do
      expect(definition_link('ref_data_spec_base')).to be_nil
    end

    it 'links a definition even when its class is not loaded into the resource registry in this process' do
      allow(Resources::Models).to receive(:resources).and_return({})
      get '/admin/reference_data/table_list_tables', params: { schema_name: 'dynamic_test' }
      expect(definition_link('ref_data_spec_recs')).to be_present
    end

    it 'links a definition without a schema name to the schema its table is found in' do
      @dm.update_column(:schema_name, nil)
      get '/admin/reference_data/table_list_tables', params: { schema_name: 'dynamic_test' }
      expect(definition_link('ref_data_spec_recs')).to be_present
    ensure
      @dm.update_column(:schema_name, 'dynamic_test')
    end
  end

  describe 'GET /admin/reference_data/table_list_columns' do
    it 'shows the view DDL in a CodeMirror section for a view' do
      get '/admin/reference_data/table_list_columns', params: { schema_name: 'dynamic_test', table_name: 'ref_data_spec_view' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('ref-view-definition')
      expect(response.body).to include('ref-view-definition__sql')
      expect(response.body).to include('ref_data_spec_base')
      expect(response.body).to include('label')
    end

    it 'does not show a view definition section for a table' do
      get '/admin/reference_data/table_list_columns', params: { schema_name: 'dynamic_test', table_name: 'ref_data_spec_base' }
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('ref-view-definition')
      expect(response.body).to include('label')
    end

    it 'responds not found for a table that does not exist' do
      get '/admin/reference_data/table_list_columns', params: { schema_name: 'dynamic_test', table_name: 'no_such_ref_table' }
      expect(response).to have_http_status(:not_found)
    end

    it 'responds not found for an injection attempt and leaves the table in place' do
      injected = "dynamic_test'); DROP TABLE dynamic_test.ref_data_spec_base; --"
      get '/admin/reference_data/table_list_columns', params: { schema_name: injected, table_name: 'ref_data_spec_base' }
      expect(response).to have_http_status(:not_found)
      expect(Admin::MigrationGenerator.table_or_view_exists_in_schema?('ref_data_spec_base', 'dynamic_test')).to be_truthy
    end
  end

  describe 'dynamic definition Table / View panel' do
    before { get "/admin/dynamic_models/#{@dm.id}/edit" }

    it 'shows the table or view for that definition in its own panel' do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="dm-table-view-panel"')
      expect(response.body).to include('ref_data_spec_recs')
      expect(response.body).to include('description')
    end
  end

  describe 'external identifier and activity log Table / View panels' do
    it 'shows the table for an external identifier in its own panel' do
      get "/admin/external_identifiers/#{@ei.id}/edit"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="dm-table-view-panel"')
      expect(response.body).to include(@ei.table_name)
      expect(response.body).to include('ref-table-col-item')
      expect(response.body).not_to include('does not exist in the database')
    end

    it 'shows the table for an activity log in its own panel' do
      get "/admin/activity_logs/#{@al.id}/edit"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="dm-table-view-panel"')
      expect(response.body).to include(@al.table_name)
      expect(response.body).to include('ref-table-col-item')
      expect(response.body).not_to include('does not exist in the database')
    end
  end
end
