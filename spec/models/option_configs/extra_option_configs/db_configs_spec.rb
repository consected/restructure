# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for DbConfigs configuration class.
# Verifies field-keyed BaseConfiguration behavior and integration through
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

  describe 'initialization' do
    it 'stores column configs directly' do
      instance = klass.new(col1: 'type_a')
      expect(instance[:col1]).to eq 'type_a'
      expect(instance.symbolize_keys).to eq(col1: 'type_a')
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
            some_column: some_value
      YAML
      expect(eo.db_configs.keys).to all(be_a Symbol)
    end

    it 'sets config_obj.db_columns from db_configs after DbConfigs runs' do
      eo = config_for(<<~YAML)
        default:
          db_configs:
            some_column: some_value
      YAML

      expect(@dm.db_columns).to eq(some_column: 'some_value')
    end
  end
end
