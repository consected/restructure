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

  before(:each) do
    create_admin
    create_user
    setup_access :trackers
    setup_access :tracker_histories
    @dm = generate_test_dynamic_model
    setup_access :dynamic_model__test_created_by_recs, user: @user
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
  end
end
