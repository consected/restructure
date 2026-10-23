# frozen_string_literal: true

require 'rails_helper'

# Tests for encrypted field support in dynamic model definitions (issue #966).
# Verifies that specifying `encrypted: true` in _db_columns configuration
# causes the dynamic model to use Rails encrypted attributes for those fields.
# The encrypted fields should:
# - Be stored as string columns in the database
# - Be encrypted/decrypted transparently via Rails `encrypts` declarations
# - Work with both new and existing dynamic model definitions
# - Be applied to DynamicModel, ActivityLog, and ExternalIdentifier definitions
RSpec.describe 'Dynamic Model Encrypted Fields', type: :model do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport
  include DynamicModelSupport

  before :all do
    create_admin
    create_user

    # Enable migrations for this test suite
    @original_allow_migrations = Settings::AllowDynamicMigrations
    change_setting('AllowDynamicMigrations', true)

    @schema_name = 'dynamic_test'
    @table_name = 'test_encrypted_fields'
    @history_table_name = 'test_encrypted_field_history'

    # Clean up any existing test tables and model
    DynamicModel.active.where(table_name: @table_name).each { |dm| dm.disable!(@admin) }
    begin
      DynamicModel.send(:remove_const, :TestEncryptedField) if DynamicModel.const_defined?(:TestEncryptedField, false)
    rescue NameError
      # Constant may have been removed by another parallel test
    end

    # Drop existing tables if they exist
    @conn = ActiveRecord::Base.connection
    @conn.execute("DROP TABLE IF EXISTS #{@schema_name}.#{@history_table_name} CASCADE")
    @conn.execute("DROP TABLE IF EXISTS #{@schema_name}.#{@table_name} CASCADE")

    # Create the dynamic model definition with encrypted column configuration
    @dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'Test Encrypted Fields',
      table_name: @table_name,
      schema_name: @schema_name,
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test,
      field_list: 'plain_text secret_data another_secret',
      options: <<~YAML
        _db_columns:
          plain_text:
            type: string
          secret_data:
            type: string
            encrypted: true
          another_secret:
            type: string
            encrypted: true
      YAML
    )

    @dm.update_tracker_events
    setup_access :dynamic_model__test_encrypted_fields
  end

  after :all do
    @dm&.disable!(@admin)
    change_setting('AllowDynamicMigrations', @original_allow_migrations)
  end

  before :each do
    @master = Master.create! current_user: @user
    @master.current_user = @user
  end

  describe 'encrypted attribute declarations' do
    it 'declares encrypts on fields marked with encrypted: true' do
      impl_class = @dm.implementation_class
      # Rails encrypted attributes are tracked in encrypted_attributes
      expect(impl_class).to respond_to(:encrypted_attributes)
      encrypted_attrs = impl_class.encrypted_attributes
      expect(encrypted_attrs).to include(:secret_data)
      expect(encrypted_attrs).to include(:another_secret)
    end

    it 'does not declare encrypts on fields without encrypted: true' do
      impl_class = @dm.implementation_class
      encrypted_attrs = impl_class.encrypted_attributes
      expect(encrypted_attrs).not_to include(:plain_text)
    end
  end

  describe 'transparent encryption and decryption' do
    it 'stores and retrieves encrypted field values transparently' do
      record = @master.dynamic_model__test_encrypted_fields.create!(
        current_user: @user,
        plain_text: 'visible text',
        secret_data: 'super secret value',
        another_secret: 'another secret value'
      )

      # Reload to ensure we get values from the database
      record.reload

      # Values should be decrypted transparently
      expect(record.plain_text).to eq('visible text')
      expect(record.secret_data).to eq('super secret value')
      expect(record.another_secret).to eq('another secret value')
    end

    it 'stores encrypted values as ciphertext in the database' do
      record = @master.dynamic_model__test_encrypted_fields.create!(
        current_user: @user,
        plain_text: 'visible text',
        secret_data: 'super secret value',
        another_secret: 'another secret value'
      )

      # Read raw values directly from the database
      raw = @conn.execute(
        "SELECT plain_text, secret_data, another_secret FROM #{@schema_name}.#{@table_name} WHERE id = #{record.id}"
      ).first

      # Plain text should be stored as-is (downcased per standard behavior)
      expect(raw['plain_text']).to eq('visible text')

      # Encrypted fields should NOT be readable as plain text in the database
      expect(raw['secret_data']).not_to eq('super secret value')
      expect(raw['another_secret']).not_to eq('another secret value')

      # Encrypted fields should contain ciphertext
      expect(raw['secret_data']).to be_present
      expect(raw['another_secret']).to be_present
    end
  end

  describe 'database column type for encrypted fields' do
    it 'creates encrypted fields as string columns in the database' do
      @conn.schema_cache.clear!
      columns = @conn.columns("#{@schema_name}.#{@table_name}")

      secret_col = columns.find { |c| c.name == 'secret_data' }
      another_col = columns.find { |c| c.name == 'another_secret' }

      expect(secret_col).not_to be_nil
      expect(another_col).not_to be_nil
      expect(secret_col.type).to eq(:string)
      expect(another_col.type).to eq(:string)
    end
  end

  describe 'db_columns configuration parsing' do
    it 'includes encrypted flag in parsed db_columns' do
      @dm.option_configs(force: true)
      db_cols = @dm.db_columns

      expect(db_cols[:secret_data]).to include(encrypted: true)
      expect(db_cols[:another_secret]).to include(encrypted: true)
      expect(db_cols[:plain_text]).not_to include(encrypted: true)
    end
  end
end
