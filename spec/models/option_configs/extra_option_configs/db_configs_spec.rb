# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for DbConfigs configuration class.
# Verifies NamedConfiguration for column definitions (type, array, index, encrypted),
# field-keyed BaseConfiguration behavior, and integration through
# ExtraOptions initialization (clean_db_configs_def behavior).
RSpec.describe 'ExtraOptionConfigs::DbConfigs', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include ExtraOptionConfigsSupport

  before(:all) do
    set_up_extra_options_configs
  end

  let(:klass) { OptionConfigs::ExtraOptionConfigs::DbConfigs }

  describe 'class structure' do
    it 'defines a NamedConfiguration inner class' do
      expect(klass.const_defined?(:NamedConfiguration)).to be true
    end

    it 'NamedConfiguration declares column config attributes' do
      nc = klass::NamedConfiguration
      expect(nc.option_types[:simple]).to include(:type, :array, :index, :encrypted)
    end
  end

  describe 'initialization' do
    it 'creates NamedConfiguration entries for hash values' do
      instance = klass.new(col1: { type: 'string', array: true })
      expect(instance[:col1]).to be_a(klass::NamedConfiguration)
      expect(instance[:col1].type).to eq 'string'
      expect(instance[:col1].array).to be true
    end

    it 'stores non-hash values directly' do
      instance = klass.new(col1: 'type_a')
      expect(instance[:col1]).to eq 'type_a'
    end

    it 'symbolize_keys converts NamedConfiguration entries to plain hashes' do
      instance = klass.new(col1: { type: 'string', encrypted: true })
      result = instance.symbolize_keys
      expect(result[:col1]).to be_a(Hash)
      expect(result[:col1][:type]).to eq 'string'
      expect(result[:col1][:encrypted]).to be true
    end
  end

  describe 'ExtraOptions integration' do
    it 'defaults db_configs to a blank DbConfigs instance when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No db configs
      YAML
      expect(eo.db_configs).to be_blank
    end

    it 'symbolizes db_configs keys' do
      eo = config_for(<<~YAML)
        default:
          db_configs:
            some_column:
              type: string
      YAML
      expect(eo.db_configs.keys).to all(be_a Symbol)
    end

    it 'sets config_obj.db_columns from db_configs after DbConfigs runs' do
      eo = config_for(<<~YAML)
        default:
          db_configs:
            some_column:
              type: string
      YAML

      expect(@dm.db_columns).to eq(some_column: { type: 'string' })
    end

    it 'warns about unrecognized keys in column config' do
      eo = config_for(<<~YAML)
        default:
          db_configs:
            some_column:
              type: string
              bogus_key: invalid
      YAML

      expect(eo.db_configs[:some_column]).to be_a(klass::NamedConfiguration)
      expect(eo.config_warnings).not_to be_empty
    end

    # Regression test for issue #1456: the unrecognized-keys warning must not
    # duplicate the field name (previously e.g. "some_column some_column contains
    # unrecognized keys [...]"), since run_validations already prepends the field
    # name once when bridging ActiveModel errors into config_warnings.
    it 'does not duplicate the field name in the unrecognized keys warning message (issue #1456)' do
      instance = klass.new(some_column: { type: 'string', bogus_key: 'invalid' })
      messages = instance.config_warnings.map { |w| w[:message] }
      warning = messages.find { |m| m.include?('unrecognized keys') }
      expect(warning).to eq 'some_column contains unrecognized keys [:bogus_key]'
    end

    # Regression test for issue #1456: the key_types mismatch error must not
    # duplicate the field name either (previously e.g. "some_column some_column
    # type must be a string...").
    it 'does not duplicate the field name in the key_types mismatch error message (issue #1456)' do
      instance = klass.new(some_column: { type: 123 })
      messages = instance.config_errors.map { |e| e[:message] }
      error = messages.find { |m| m.include?('must be a string') }
      expect(error).to eq 'some_column type must be a string, current value: 123 (Integer)'
    end
  end
end
