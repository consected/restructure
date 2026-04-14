# frozen_string_literal: true

require 'rails_helper'

# Tests for Imports::Import model - Issue #991
#
# When a dynamic model is created from a CSV file that lacks the standard
# id, created_at, updated_at columns, those columns are auto-added to the
# database table. Subsequent CSV imports should handle both cases:
#
# 1. CSV WITHOUT id/created_at/updated_at columns: should succeed and
#    auto-populate created_at and updated_at with the current time.
#    Each timestamp is handled independently.
# 2. CSV WITH id/created_at/updated_at columns: should succeed and
#    use the values provided in the CSV (even if blank)
RSpec.describe Imports::Import, type: :model do
  include ModelSupport
  include UserSupport

  before :all do
    change_setting('AllowDynamicMigrations', true)

    create_admin

    # Create a dynamic model from the CSV without core fields.
    # The ModelGenerator will auto-add id, created_at, updated_at to the table.
    csv = File.read('spec/fixtures/import/test-types.csv')
    @full_table_name = "dynamic_test.test_importcsvspecs#{rand 100_000_000_000_000}_recs"
    ds = Imports::ModelGenerator.new(
      dynamic_model_table: @full_table_name,
      category: 'dynamic-test-env',
      current_admin: @admin
    )
    ds.analyze_csv(csv)
    @dm = ds.create_dynamic_model
    expect(ds.dynamic_model_ready?).to be_truthy

    # The dynamic model should have the CSV fields plus auto-added core fields
    expect(@dm.field_list_array).to eq %w[a_string a_int a_float a_date a_time a_mixed_string a_boolean a_unknown a_string2]

    @short_table_name = @full_table_name.split('.').last
    @resource_name = "dynamic_model__#{@short_table_name}"
  end

  after :all do
    change_setting('AllowDynamicMigrations', false)
  end

  before :example do
    create_admin
    create_user
    # Grant the user table-level access so the model appears in accepts_models
    setup_access @resource_name.to_sym, resource_type: :table, access: :create, user: @user
  end

  describe 'importing CSV without id, created_at, updated_at columns' do
    let(:csv_without_core) { File.read('spec/fixtures/import/test-types.csv') }

    it 'succeeds without errors' do
      import = Imports::Import.setup_import(@resource_name, @user, 'test-types.csv')
      expect(import).to be_persisted

      import.import_csv(csv_without_core)

      expect(import.errors).to be_empty,
                               "Expected no errors but got: #{import.errors.full_messages.join(', ')}"
    end

    it 'auto-populates created_at and updated_at on built items' do
      import = Imports::Import.setup_import(@resource_name, @user, 'test-types.csv')
      before_import = Time.now
      import.import_csv(csv_without_core)

      expect(import.errors).to be_empty,
                               "Expected no errors but got: #{import.errors.full_messages.join(', ')}"
      expect(import.items).to be_present
      expect(import.items.length).to eq 4

      import.items.each do |item|
        expect(item.created_at).to be_present,
                                   'Expected created_at to be auto-populated but it was nil'
        expect(item.updated_at).to be_present,
                                   'Expected updated_at to be auto-populated but it was nil'
        expect(item.created_at).to be >= before_import
        expect(item.updated_at).to be >= before_import
      end
    end
  end

  describe 'importing CSV with id, created_at, updated_at columns' do
    let(:csv_with_core) { File.read('spec/fixtures/import/test-types-with-core-fields.csv') }

    it 'succeeds without errors when core fields are present in the CSV' do
      import = Imports::Import.setup_import(@resource_name, @user, 'test-types-with-core-fields.csv')
      expect(import).to be_persisted

      import.import_csv(csv_with_core)

      expect(import.errors).to be_empty,
                               "Expected no errors but got: #{import.errors.full_messages.join(', ')}"
    end

    it 'uses the CSV-provided created_at and updated_at values on built items' do
      import = Imports::Import.setup_import(@resource_name, @user, 'test-types-with-core-fields.csv')
      import.import_csv(csv_with_core)

      expect(import.errors).to be_empty,
                               "Expected no errors but got: #{import.errors.full_messages.join(', ')}"
      expect(import.items).to be_present

      # First row has explicit timestamps
      first_item = import.items.first
      expect(first_item.created_at).to be_present,
                                       'Expected created_at from CSV to be set but it was nil'
      expected_time = Time.zone.parse('2020-12-02 15:43:00')
      expect(first_item.created_at).to be_within(1.second).of(expected_time)
      expect(first_item.updated_at).to be_within(1.second).of(expected_time)
    end

    it 'handles blank created_at and updated_at in the CSV gracefully' do
      import = Imports::Import.setup_import(@resource_name, @user, 'test-types-with-core-fields.csv')
      import.import_csv(csv_with_core)

      expect(import.errors).to be_empty,
                               "Expected no errors but got: #{import.errors.full_messages.join(', ')}"
      expect(import.items).to be_present

      # Last row has blank timestamps - should still be handled gracefully
      import.items.last
      # Blank timestamps should either be nil or auto-populated, not cause an error
      expect(import.errors).to be_empty
    end
  end

  describe 'importing CSV with only created_at (no updated_at)' do
    let(:csv_created_only) { File.read('spec/fixtures/import/test-types-with-created-at-only.csv') }

    it 'uses CSV created_at and auto-populates updated_at independently' do
      import = Imports::Import.setup_import(@resource_name, @user, 'test-types-with-created-at-only.csv')
      before_import = Time.now
      import.import_csv(csv_created_only)

      expect(import.errors).to be_empty,
                               "Expected no errors but got: #{import.errors.full_messages.join(', ')}"
      expect(import.items).to be_present

      # First row has explicit created_at but no updated_at column in CSV
      first_item = import.items.first
      expected_created = Time.zone.parse('2020-12-02 15:43:00')
      expect(first_item.created_at).to be_within(1.second).of(expected_created)
      # updated_at should be auto-populated since it's not in the CSV
      expect(first_item.updated_at).to be >= before_import
    end
  end
end
