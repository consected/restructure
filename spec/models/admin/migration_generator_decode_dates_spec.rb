# frozen_string_literal: true

require 'rails_helper'

# Regression coverage for issue #1295 (active_record.postgresql_adapter_decode_dates).
# Confirms raw-SQL execution paths correctly hand back Ruby Date objects for `date`-typed
# columns now that the app-wide Rails 7.2 default is adopted (rather than a String), across
# the two code paths raw SQL can take in this app:
# - `connection.execute` / `exec_query` (used by Admin::MigrationGenerator and
#   Dynamic::VersionHandler for schema introspection and definition history)
# - `Reports::Runner#run` (config-driven report SQL), which installs its own
#   PG::BasicTypeMapForResults on the result - this spec locks in that it still decodes dates
#   correctly and is unaffected either way by the Rails-level setting.
RSpec.describe 'Raw-SQL date decoding (issue #1295)', type: :model do
  # Use the dedicated dynamic_test schema for test-only tables, per repo convention.
  SCHEMA = 'dynamic_test'
  TABLE = 'decode_dates_audit_test'

  before :all do
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS #{SCHEMA}.#{TABLE} (
        id serial PRIMARY KEY,
        event_date date NOT NULL
      )
    SQL
    ActiveRecord::Base.connection.execute(
      "INSERT INTO #{SCHEMA}.#{TABLE} (event_date) VALUES ('2026-06-15')"
    )
  end

  after :all do
    ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS #{SCHEMA}.#{TABLE} CASCADE")
    Admin::MigrationGenerator.tables_and_views_reset!
  end

  it 'confirms the adapter-level setting is enabled' do
    expect(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.decode_dates).to be true
  end

  it 'decodes a raw ::date literal as a Ruby Date via connection.execute' do
    result = Admin::MigrationGenerator.connection.execute("select '2026-06-15'::date as d")
    expect(result.first['d']).to eq(Date.new(2026, 6, 15))
  end

  it 'decodes a date-typed column from a raw SELECT * consumed as a plain hash' do
    row = Admin::MigrationGenerator.connection.execute("select * from #{SCHEMA}.#{TABLE}").to_a.first
    expect(row['event_date']).to eq(Date.new(2026, 6, 15))
  end

  it 'decodes a date-typed column via exec_query, the ActiveRecord::Result path used by ' \
     'Admin::MigrationGenerator and FullTextSearch::TsvectorWriter' do
    result = ActiveRecord::Base.connection.exec_query("select event_date from #{SCHEMA}.#{TABLE}")
    expect(result.first['event_date']).to eq(Date.new(2026, 6, 15))
  end

  it 'decodes a date-typed column through Reports::Runner#run, which installs its own ' \
     'PG::BasicTypeMapForResults independently of this setting' do
    report = Report.new(sql: "select '2026-06-15'::date as report_date", search_attrs: '')
    runner = Reports::Runner.new(report)

    results = runner.run({})

    expect(results.first['report_date']).to eq(Date.new(2026, 6, 15))
  end
end
