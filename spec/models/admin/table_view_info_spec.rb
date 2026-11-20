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
    SQL
    Admin::MigrationGenerator.tables_and_views_reset!
  end

  after(:all) do
    ActiveRecord::Base.connection.execute <<~SQL
      DROP VIEW IF EXISTS dynamic_test.ref_data_spec_view;
      DROP TABLE IF EXISTS dynamic_test.ref_data_spec_base;
      DROP TABLE IF EXISTS dynamic_test.ref_data_spec_base_history;
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

    it 'flags history tables so they can be filtered out of the search' do
      expect(by_label['dynamic_test.ref_data_spec_base_history']).to include(history: true)
      expect(by_label['dynamic_test.ref_data_spec_base']).to include(history: false)
    end
  end
end
