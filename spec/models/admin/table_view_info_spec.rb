# frozen_string_literal: true

# Table / view info spec (issue #1567)
#
# Verifies Admin::TableViewInfo, and the view definition lookup in Admin::MigrationGenerator,
# which back the Tables tab of the reference data admin page and the Table / View panel of
# dynamic definition admin pages.
#
# Covers:
# - a table is reported as a table, and a view as a view, with its DDL from pg_views
# - unknown tables, and schemas outside the app search path, are not reported as existing
# - schema and table names are treated as literal values, never as SQL (injection attempts)
# - materialized views (not in information_schema) are found, typed, have columns and DDL, and are searchable
# - MigrationGenerator.views, .materialized_views and .view_in_schema? use cached names that are reset
# - the same table name in two schemas resolves to the schema asked for

require 'rails_helper'

RSpec.describe Admin::TableViewInfo do
  let(:schema) { 'dynamic_test' }

  before(:all) do
    ActiveRecord::Base.connection.execute <<~SQL
      DROP VIEW IF EXISTS dynamic_test.ref_data_spec_view;
      DROP TABLE IF EXISTS dynamic_test.ref_data_spec_base;
      CREATE TABLE dynamic_test.ref_data_spec_base (id integer PRIMARY KEY, label varchar);
      CREATE VIEW dynamic_test.ref_data_spec_view AS SELECT id, label FROM dynamic_test.ref_data_spec_base;
      DROP TABLE IF EXISTS dynamic_test.ref_data_spec_base_history;
      CREATE TABLE dynamic_test.ref_data_spec_base_history (id integer);
      DROP MATERIALIZED VIEW IF EXISTS dynamic_test.ref_data_spec_matview;
      CREATE MATERIALIZED VIEW dynamic_test.ref_data_spec_matview AS SELECT id, label FROM dynamic_test.ref_data_spec_base;
      DROP TABLE IF EXISTS dynamic_test.ref_data_spec_dup;
      DROP TABLE IF EXISTS redcap_test.ref_data_spec_dup;
      CREATE TABLE dynamic_test.ref_data_spec_dup (in_dynamic_test integer);
      CREATE TABLE redcap_test.ref_data_spec_dup (in_redcap_test integer);
    SQL
    Admin::MigrationGenerator.tables_and_views_reset!
  end

  after(:all) do
    ActiveRecord::Base.connection.execute <<~SQL
      DROP MATERIALIZED VIEW IF EXISTS dynamic_test.ref_data_spec_matview;
      DROP VIEW IF EXISTS dynamic_test.ref_data_spec_view;
      DROP TABLE IF EXISTS dynamic_test.ref_data_spec_base;
      DROP TABLE IF EXISTS dynamic_test.ref_data_spec_base_history;
      DROP TABLE IF EXISTS dynamic_test.ref_data_spec_dup;
      DROP TABLE IF EXISTS redcap_test.ref_data_spec_dup;
    SQL
    Admin::MigrationGenerator.tables_and_views_reset!
  end

  def info(table_name, schema_name: schema)
    described_class.new(schema_name:, table_name:)
  end

  describe 'a table' do
    subject(:table_info) { info('ref_data_spec_base') }

    it 'exists and is identified as a table' do
      expect(table_info.exists?).to be_truthy
      expect(table_info.object_type).to eq :table
    end

    it 'has no view definition' do
      expect(table_info.view_definition).to be_nil
    end

    it 'lists its columns' do
      expect(table_info.columns.map(&:name)).to eq %w[id label]
    end
  end

  describe 'a view' do
    subject(:view_info) { info('ref_data_spec_view') }

    it 'exists and is identified as a view' do
      expect(view_info.exists?).to be_truthy
      expect(view_info.object_type).to eq :view
    end

    it 'returns the view DDL from the database' do
      expect(view_info.view_definition).to include 'ref_data_spec_base'
      expect(view_info.view_definition).to match(/SELECT/i)
    end

    it 'lists the columns of the view' do
      expect(view_info.columns.map(&:name)).to eq %w[id label]
    end
  end

  describe 'a materialized view' do
    subject(:matview_info) { info('ref_data_spec_matview') }

    it 'exists and is identified as a materialized view, not a plain view' do
      expect(matview_info.exists?).to be_truthy
      expect(matview_info.object_type).to eq :materialized_view
      expect(matview_info.view?).to be false
      expect(matview_info.definition?).to be true
    end

    it 'returns the DDL and lists the columns' do
      expect(matview_info.view_definition).to include 'ref_data_spec_base'
      expect(matview_info.columns.map(&:name)).to eq %w[id label]
    end

    it 'is not stopped from being found by the existence checks used by migrations' do
      expect(Admin::MigrationGenerator.table_or_view_exists?('dynamic_test.ref_data_spec_matview')).to be_truthy
      expect(Admin::MigrationGenerator.table_schema_hash['ref_data_spec_matview']).to eq 'dynamic_test'
    end
  end

  describe 'the same table name in two schemas' do
    it 'resolves columns for the schema asked for' do
      expect(info('ref_data_spec_dup', schema_name: 'dynamic_test').columns.map(&:name)).to eq %w[in_dynamic_test]
      expect(info('ref_data_spec_dup', schema_name: 'redcap_test').columns.map(&:name)).to eq %w[in_redcap_test]
    end
  end

  describe 'Admin::MigrationGenerator view lookups' do
    let(:generator) { Admin::MigrationGenerator }

    it '.views lists plain views only, and .materialized_views lists materialized views only' do
      views = generator.views.map { |v| [v['schema_name'], v['table_name']] }
      matviews = generator.materialized_views.map { |v| [v['schema_name'], v['table_name']] }
      expect(views).to include(%w[dynamic_test ref_data_spec_view])
      expect(views).not_to include(%w[dynamic_test ref_data_spec_matview])
      expect(matviews).to include(%w[dynamic_test ref_data_spec_matview])
      expect(matviews).not_to include(%w[dynamic_test ref_data_spec_view])
    end

    it '.tables_and_views includes tables, views and materialized views' do
      names = generator.tables_and_views.map { |t| t['table_name'] }
      expect(names).to include('ref_data_spec_base', 'ref_data_spec_view', 'ref_data_spec_matview')
    end

    it '.view_in_schema? is true only for a view in the named schema' do
      expect(generator.view_in_schema?('ref_data_spec_view', 'dynamic_test')).to be true
      expect(generator.view_in_schema?('ref_data_spec_view', 'redcap_test')).to be false
      expect(generator.view_in_schema?('ref_data_spec_base', 'dynamic_test')).to be false
      expect(generator.view_in_schema?('ref_data_spec_matview', 'dynamic_test')).to be false
      expect(generator.materialized_view_in_schema?('ref_data_spec_matview', 'dynamic_test')).to be true
    end

    it 'caches the view names until the tables and views are reset' do
      generator.view_in_schema?('ref_data_spec_view', 'dynamic_test')
      ActiveRecord::Base.connection.execute 'CREATE VIEW dynamic_test.ref_data_spec_view2 AS SELECT 1 AS n'
      expect(generator.view_in_schema?('ref_data_spec_view2', 'dynamic_test')).to be false
      generator.tables_and_views_reset!
      expect(generator.view_in_schema?('ref_data_spec_view2', 'dynamic_test')).to be true
    ensure
      ActiveRecord::Base.connection.execute 'DROP VIEW IF EXISTS dynamic_test.ref_data_spec_view2'
      generator.tables_and_views_reset!
    end

    it '.view_definition does not clear the schema cache' do
      expect(ActiveRecord::Base.connection.schema_cache).not_to receive(:clear!)
      expect(generator.view_definition(schema, 'ref_data_spec_view')).to include 'ref_data_spec_base'
    end
  end

  describe 'names that are not visible to the app' do
    it 'does not report an unknown table as existing' do
      expect(info('no_such_table_for_ref_data').exists?).to be_falsey
      expect(info('no_such_table_for_ref_data').object_type).to be_nil
    end

    it 'does not report a schema outside the search path as existing' do
      expect(info('pg_class', schema_name: 'pg_catalog').exists?).to be_falsey
      expect(info('pg_class', schema_name: 'pg_catalog').view_definition).to be_nil
    end

    it 'treats an injection attempt in the schema name as a literal and reports nothing' do
      injected = info('ref_data_spec_base', schema_name: "dynamic_test' OR '1'='1")
      expect(injected.exists?).to be_falsey
      expect(injected.view_definition).to be_nil
    end

    it 'treats an injection attempt in the table name as a literal' do
      injected = info("ref_data_spec_view' OR '1'='1")
      expect(injected.exists?).to be_falsey
      expect(Admin::MigrationGenerator.view_definition(schema, "ref_data_spec_view' OR '1'='1")).to be_nil
    end

    it 'leaves the underlying table in place after an injection attempt' do
      info("x'); DROP TABLE dynamic_test.ref_data_spec_base; --").exists?
      expect(info('ref_data_spec_base').exists?).to be_truthy
    end
  end

  describe '.search_items' do
    let(:by_label) { described_class.search_items.index_by { |item| item[:label] } }

    it 'lists tables and views with their schema, so a search does not need a schema chosen first' do
      expect(by_label['dynamic_test.ref_data_spec_view']).to include(schema: 'dynamic_test',
                                                                     table: 'ref_data_spec_view',
                                                                     object_type: 'view')
      expect(by_label['dynamic_test.ref_data_spec_base']).to include(object_type: 'table')
    end

    it 'lists a materialized view as its own object type' do
      expect(by_label['dynamic_test.ref_data_spec_matview']).to include(object_type: 'materialized_view')
    end

    it 'flags history tables so they can be filtered out of the search' do
      expect(by_label['dynamic_test.ref_data_spec_base_history']).to include(history: true)
      expect(by_label['dynamic_test.ref_data_spec_base']).to include(history: false)
    end
  end
end
