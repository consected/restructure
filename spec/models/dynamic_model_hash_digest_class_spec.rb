# frozen_string_literal: true

require 'rails_helper'

# Tests for per-field hash_digest_class option on dynamic model encrypted fields (issue #1294).
# Verifies that when a dynamic model _db_columns field specifies hash_digest_class,
# the generated implementation class uses the correct digest for key derivation:
# - Default (no option): encrypts with SHA256
# - hash_digest_class: sha1: encrypts with SHA1 (for legacy data compatibility)
# - Switching the option regenerates the implementation class with the new digest
# Proves which digest was actually used by reading the raw ciphertext directly from the
# database and decrypting it with an independent ActiveRecord::Encryption::Encryptor and
# digest-restricted key_provider, bypassing the model's attribute layer entirely. This
# avoids relying on ActiveRecord::Encryption.with_encryption_context, which cannot override
# a field's own explicit key_provider (Rails always checks the attribute's own key_provider
# first - see ActiveRecord::Encryption::Scheme#key_provider).
RSpec.describe 'Dynamic Model hash_digest_class option', type: :model do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport
  include DynamicModelSupport

  before :all do
    create_admin
    create_user

    @original_allow_migrations = Settings::AllowDynamicMigrations
    change_setting('AllowDynamicMigrations', true)

    @schema_name = 'dynamic_test'
    @table_name = 'test_hash_digest_fields'
    @history_table_name = 'test_hash_digest_field_history'

    # Clean up any existing test tables and model
    DynamicModel.active.where(table_name: @table_name).each { |dm| dm.disable!(@admin) }
    begin
      DynamicModel.send(:remove_const, :TestHashDigestField) if DynamicModel.const_defined?(:TestHashDigestField, false)
    rescue NameError
      # Constant may have been removed by another parallel test
    end

    # Drop existing tables if they exist
    @conn = ActiveRecord::Base.connection
    @conn.execute("DROP TABLE IF EXISTS #{@schema_name}.#{@history_table_name} CASCADE")
    @conn.execute("DROP TABLE IF EXISTS #{@schema_name}.#{@table_name} CASCADE")

    # Create the dynamic model definition with encrypted columns and hash_digest_class options
    @dm = DynamicModel.create!(
      current_admin: @admin,
      name: 'Test Hash Digest Fields',
      table_name: @table_name,
      schema_name: @schema_name,
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test,
      field_list: 'plain_text default_digest_secret sha1_secret',
      options: <<~YAML
        _db_columns:
          plain_text:
            type: string
          default_digest_secret:
            type: string
            encrypted: true
          sha1_secret:
            type: string
            encrypted: true
            hash_digest_class: sha1
      YAML
    )

    @dm.update_tracker_events
    setup_access :dynamic_model__test_hash_digest_fields
  end

  after :all do
    @dm&.disable!(@admin)
    change_setting('AllowDynamicMigrations', @original_allow_migrations)
  end

  before :each do
    @master = Master.create! current_user: @user
    @master.current_user = @user
  end

  # Builds a key provider restricted to only SHA1-derived keys (no fallback).
  # Used to independently prove which digest a ciphertext was produced with.
  def legacy_sha1_key_provider
    key_generator = ActiveRecord::Encryption::KeyGenerator.new(hash_digest_class: OpenSSL::Digest::SHA1)
    ActiveRecord::Encryption::DerivedSecretKeyProvider.new(
      ActiveRecord::Encryption.config.primary_key,
      key_generator: key_generator
    )
  end

  # Builds a key provider restricted to only SHA256-derived keys (no fallback).
  def sha256_key_provider
    key_generator = ActiveRecord::Encryption::KeyGenerator.new(hash_digest_class: OpenSSL::Digest::SHA256)
    ActiveRecord::Encryption::DerivedSecretKeyProvider.new(
      ActiveRecord::Encryption.config.primary_key,
      key_generator: key_generator
    )
  end

  # Reads the raw (still-encrypted) column value directly from the database,
  # bypassing the model's attribute layer entirely.
  def raw_ciphertext(record, column)
    ActiveRecord::Base.connection.execute(
      "SELECT #{column} FROM #{@schema_name}.#{@table_name} WHERE id = #{record.id}"
    ).first[column.to_s]
  end

  # Writes a raw ciphertext string directly to the database column via SQL,
  # bypassing the model's attribute layer entirely. Note update_column/update_columns
  # cannot be used for this: Rails re-serializes (re-encrypts) attribute values written
  # that way, so it would double-encrypt an already-encrypted string.
  def write_raw_ciphertext(record, column, ciphertext)
    quoted = ActiveRecord::Base.connection.quote(ciphertext)
    ActiveRecord::Base.connection.execute(
      "UPDATE #{@schema_name}.#{@table_name} SET #{column} = #{quoted} WHERE id = #{record.id}"
    )
  end

  describe 'default digest is SHA256 when hash_digest_class is not specified' do
    it 'encrypts the field with SHA256, provably via an independent SHA1-only decrypt attempt on the raw ciphertext failing' do
      record = @master.dynamic_model__test_hash_digest_fields.create!(
        current_user: @user,
        plain_text: 'visible',
        default_digest_secret: 'top secret default'
      )
      record.reload

      # Normal read works
      expect(record.default_digest_secret).to eq('top secret default')

      # Independently prove the digest used: a SHA1-only key_provider must fail to
      # decrypt the raw ciphertext, while a SHA256-only key_provider succeeds.
      ciphertext = raw_ciphertext(record, :default_digest_secret)
      expect do
        ActiveRecord::Encryption::Encryptor.new.decrypt(ciphertext, key_provider: legacy_sha1_key_provider)
      end.to raise_error(ActiveRecord::Encryption::Errors::Decryption)

      expect(
        ActiveRecord::Encryption::Encryptor.new.decrypt(ciphertext, key_provider: sha256_key_provider)
      ).to eq('top secret default')
    end

    it 'defaults to SHA256 even when the global ActiveRecord::Encryption default is SHA1' do
      original = ActiveRecord::Encryption.config.hash_digest_class
      ActiveRecord::Encryption.config.hash_digest_class = OpenSSL::Digest::SHA1

      record = @master.dynamic_model__test_hash_digest_fields.create!(
        current_user: @user,
        plain_text: 'visible',
        default_digest_secret: 'independent of global config'
      )
      record.reload

      ciphertext = raw_ciphertext(record, :default_digest_secret)
      expect(
        ActiveRecord::Encryption::Encryptor.new.decrypt(ciphertext, key_provider: sha256_key_provider)
      ).to eq('independent of global config')
    ensure
      ActiveRecord::Encryption.config.hash_digest_class = original
    end
  end

  describe 'hash_digest_class: sha1 uses SHA1 as primary digest for new writes' do
    it 'writes with SHA1, provably via an independent SHA1-only decrypt of the raw ciphertext succeeding' do
      record = @master.dynamic_model__test_hash_digest_fields.create!(
        current_user: @user,
        plain_text: 'visible',
        sha1_secret: 'legacy compatible secret'
      )
      record.reload

      # Normal read works
      expect(record.sha1_secret).to eq('legacy compatible secret')

      # Independently prove the field's primary key derivation uses SHA1 by decrypting
      # the raw ciphertext with a SHA1-only key_provider, bypassing the model entirely.
      ciphertext = raw_ciphertext(record, :sha1_secret)
      expect(
        ActiveRecord::Encryption::Encryptor.new.decrypt(ciphertext, key_provider: legacy_sha1_key_provider)
      ).to eq('legacy compatible secret')
    end
  end

  describe 'hash_digest_class: sha1 can read data encrypted under the legacy SHA1 key' do
    it 'decrypts a value written directly under a SHA1 key_provider via the fields own config' do
      record = @master.dynamic_model__test_hash_digest_fields.create!(
        current_user: @user,
        plain_text: 'visible'
      )

      # Simulate genuinely-independent legacy data: build ciphertext directly with an
      # independent Encryptor/key_provider, then write it straight to the raw column via
      # SQL, bypassing the model's own encrypting writer entirely.
      ciphertext = ActiveRecord::Encryption::Encryptor.new.encrypt('old legacy value', key_provider: legacy_sha1_key_provider)
      write_raw_ciphertext(record, :sha1_secret, ciphertext)

      # Read back via normal model. The sha1_secret field's own encrypts declaration
      # uses SHA1 as primary, so decryption works via the field's own key_provider.
      expect(record.reload.sha1_secret).to eq('old legacy value')
    end
  end

  describe 'switching hash_digest_class is reflected in regenerated implementation class' do
    it 'uses SHA256 after switching from sha1 to sha256' do
      # First, prove that with hash_digest_class: sha1, the field writes with SHA1.
      record = @master.dynamic_model__test_hash_digest_fields.create!(
        current_user: @user,
        plain_text: 'visible',
        sha1_secret: 'before switch'
      )
      record.reload

      # Verify original config writes with SHA1: independent SHA1-only decrypt of the
      # raw ciphertext must succeed.
      before_ciphertext = raw_ciphertext(record, :sha1_secret)
      expect(
        ActiveRecord::Encryption::Encryptor.new.decrypt(before_ciphertext, key_provider: legacy_sha1_key_provider)
      ).to eq('before switch')

      # Now change the definition to use sha256 for sha1_secret
      @dm.update!(
        current_admin: @admin,
        options: <<~YAML
          _db_columns:
            plain_text:
              type: string
            default_digest_secret:
              type: string
              encrypted: true
            sha1_secret:
              type: string
              encrypted: true
              hash_digest_class: sha256
        YAML
      )

      # Force regeneration of the implementation class
      begin
        DynamicModel.send(:remove_const, :TestHashDigestField) if DynamicModel.const_defined?(:TestHashDigestField, false)
      rescue NameError
        nil
      end
      @dm.option_configs(force: true)
      @dm.generate_model

      impl_class = @dm.implementation_class

      # Write a NEW value after the switch
      new_record = impl_class.create!(
        master_id: @master.id,
        current_user: @user,
        plain_text: 'post-switch',
        sha1_secret: 'after switch value'
      )
      new_record.reload
      expect(new_record.sha1_secret).to eq('after switch value')

      # Prove the new value was encrypted with SHA256: an independent SHA1-only decrypt
      # of the raw ciphertext must FAIL, while a SHA256-only decrypt succeeds.
      after_ciphertext = raw_ciphertext(new_record, :sha1_secret)
      expect do
        ActiveRecord::Encryption::Encryptor.new.decrypt(after_ciphertext, key_provider: legacy_sha1_key_provider)
      end.to raise_error(ActiveRecord::Encryption::Errors::Decryption)
      expect(
        ActiveRecord::Encryption::Encryptor.new.decrypt(after_ciphertext, key_provider: sha256_key_provider)
      ).to eq('after switch value')

      # Restore the original config for other tests
      @dm.update!(
        current_admin: @admin,
        options: <<~YAML
          _db_columns:
            plain_text:
              type: string
            default_digest_secret:
              type: string
              encrypted: true
            sha1_secret:
              type: string
              encrypted: true
              hash_digest_class: sha1
        YAML
      )
      begin
        DynamicModel.send(:remove_const, :TestHashDigestField) if DynamicModel.const_defined?(:TestHashDigestField, false)
      rescue NameError
        nil
      end
      @dm.option_configs(force: true)
      @dm.generate_model
    end
  end

  describe 'unsupported hash_digest_class surfaces a validation error on the definition' do
    it 'reports a config error when an invalid hash_digest_class is specified' do
      @dm.update!(
        current_admin: @admin,
        options: <<~YAML
          _db_columns:
            plain_text:
              type: string
            default_digest_secret:
              type: string
              encrypted: true
            sha1_secret:
              type: string
              encrypted: true
              hash_digest_class: md5
        YAML
      )
      @dm.reload
      @dm.option_configs(force: true)

      db_cols = @dm.db_columns
      db_cols.valid?

      # The validation should produce an error mentioning hash_digest_class and the bad value
      all_messages = db_cols.errors.full_messages.join(' ')
      expect(all_messages).to include('hash_digest_class')

      # Restore valid config
      @dm.update!(
        current_admin: @admin,
        options: <<~YAML
          _db_columns:
            plain_text:
              type: string
            default_digest_secret:
              type: string
              encrypted: true
            sha1_secret:
              type: string
              encrypted: true
              hash_digest_class: sha1
        YAML
      )
      @dm.reload
      @dm.option_configs(force: true)
    end

    # Config validation (above) is advisory only - it does not block save/generate_model.
    # build_digest_key_provider must independently enforce the same allowlist, so an admin
    # saving an unsupported value doesn't silently end up with a working MD5-derived
    # provider, or a NameError crashing model generation on a typo. Compare the actual
    # derived key bytes (key_generator isn't exposed on DerivedSecretKeyProvider) against a
    # known-SHA256 provider to prove the fallback, rather than just checking it doesn't raise.
    it 'falls back to SHA256 in the key provider itself, not just the advisory validation' do
      sha256_secret = sha256_key_provider.encryption_key.secret

      expect(@dm.send(:build_digest_key_provider, 'md5').encryption_key.secret).to eq(sha256_secret)
      expect(@dm.send(:build_digest_key_provider, 'sha3').encryption_key.secret).to eq(sha256_secret)
      expect(@dm.send(:build_digest_key_provider, nil).encryption_key.secret).to eq(sha256_secret)
      expect(@dm.send(:build_digest_key_provider, 'sha1').encryption_key.secret)
        .to eq(legacy_sha1_key_provider.encryption_key.secret)
      expect(@dm.send(:build_digest_key_provider, 'sha1').encryption_key.secret).not_to eq(sha256_secret)
    end
  end
end
