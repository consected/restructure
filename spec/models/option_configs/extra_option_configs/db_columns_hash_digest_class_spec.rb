# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for hash_digest_class support in DbColumns configuration (issue #1294).
# Verifies that the _db_columns configuration accepts an optional hash_digest_class
# attribute on encrypted fields, defaults to SHA256 when omitted, validates against
# unsupported values, and integrates cleanly through ExtraOptions.parse_config.
RSpec.describe 'ExtraOptionConfigs::DbColumns hash_digest_class', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include ExtraOptionConfigsSupport

  before(:all) do
    set_up_extra_options_configs
  end

  let(:klass) { OptionConfigs::ExtraOptionConfigs::DbColumns }

  describe 'hash_digest_class attribute recognition' do
    it 'does not warn about hash_digest_class when set to sha256 as a string' do
      instance = klass.new(secret: { type: 'string', encrypted: true, hash_digest_class: 'sha256' })
      expect(instance.config_warnings).to be_empty
    end

    it 'does not warn about hash_digest_class when set to sha1 as a string' do
      instance = klass.new(secret: { type: 'string', encrypted: true, hash_digest_class: 'sha1' })
      expect(instance.config_warnings).to be_empty
    end

    it 'does not warn about hash_digest_class when set to :sha256 as a symbol' do
      instance = klass.new(secret: { type: 'string', encrypted: true, hash_digest_class: :sha256 })
      expect(instance.config_warnings).to be_empty
    end

    it 'does not warn about hash_digest_class when set to :sha1 as a symbol' do
      instance = klass.new(secret: { type: 'string', encrypted: true, hash_digest_class: :sha1 })
      expect(instance.config_warnings).to be_empty
    end

    it 'does not warn or error when hash_digest_class is omitted entirely' do
      instance = klass.new(secret: { type: 'string', encrypted: true })
      expect(instance.config_warnings).to be_empty
      instance.valid?
      expect(instance.errors).to be_empty
    end
  end

  describe 'hash_digest_class validation' do
    it 'rejects unsupported hash_digest_class value md5' do
      instance = klass.new(secret: { type: 'string', encrypted: true, hash_digest_class: 'md5' })
      instance.valid?
      expect(instance.errors.full_messages.join).to include('hash_digest_class')
      expect(instance.errors.full_messages.join).to match(/md5|unsupported|invalid|allowed/i)
    end

    it 'rejects unsupported hash_digest_class value sha512' do
      instance = klass.new(secret: { type: 'string', encrypted: true, hash_digest_class: 'sha512' })
      instance.valid?
      expect(instance.errors.full_messages.join).to include('hash_digest_class')
      expect(instance.errors.full_messages.join).to match(/sha512|unsupported|invalid|allowed/i)
    end

    it 'rejects unsupported hash_digest_class value as a symbol' do
      instance = klass.new(secret: { type: 'string', encrypted: true, hash_digest_class: :md5 })
      instance.valid?
      expect(instance.errors.full_messages.join).to include('hash_digest_class')
    end
  end

  describe 'combined valid configuration including hash_digest_class' do
    it 'passes validation with all keys set correctly including hash_digest_class' do
      instance = klass.new(
        email: { type: 'string', index: true, encrypted: true, hash_digest_class: 'sha256' },
        legacy_secret: { type: 'string', encrypted: true, hash_digest_class: 'sha1' },
        tags: { type: 'string', array: true },
        score: { type: 'float' }
      )
      instance.valid?
      expect(instance.errors).to be_empty
      expect(instance.config_warnings).to be_empty
    end
  end

  describe 'parse_config integration with hash_digest_class' do
    it 'stores hash_digest_class accessible via dig on the parsed DbColumns' do
      @dm.update!(options: <<~YAML)
        _db_columns:
          alt_secret:
            type: string
            encrypted: true
            hash_digest_class: sha1
        default:
          label: Test
      YAML
      @dm.reload
      @dm.option_configs force: true

      expect(@dm.db_columns).to be_a(klass)
      expect(@dm.db_columns.dig(:alt_secret, :hash_digest_class)).to eq 'sha1'
    end
  end
end
