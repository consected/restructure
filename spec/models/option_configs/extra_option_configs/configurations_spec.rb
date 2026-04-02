# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for Configurations class (top-level _configurations options).
# Verifies Hash-like access ([], dig, reject, key?), recognized key warnings,
# and integration through ExtraOptions.parse_config.
RSpec.describe 'ExtraOptionConfigs::Configurations', type: :model do
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

  let(:klass) { OptionConfigs::ExtraOptionConfigs::Configurations }

  describe 'initialization' do
    it 'stores configuration values accessible via []' do
      instance = klass.new(secondary_key: 'alt_id', prevent_migrations: true)
      expect(instance[:secondary_key]).to eq 'alt_id'
      expect(instance[:prevent_migrations]).to be true
    end

    it 'supports dig for nested access' do
      instance = klass.new(batch_trigger: { frequency: '1 hour', limit: 100 })
      expect(instance.dig(:batch_trigger, :frequency)).to eq '1 hour'
      expect(instance.dig(:batch_trigger, :limit)).to eq 100
    end

    it 'supports reject returning a Hash' do
      instance = klass.new(secondary_key: 'x', view_sql: 'SELECT 1')
      result = instance.reject { |k, _v| k == :view_sql }
      expect(result).to be_a(Hash)
      expect(result.keys).to eq([:secondary_key])
    end

    it 'is blank when empty' do
      instance = klass.new({})
      expect(instance).to be_blank
    end

    it 'is truthy even when empty' do
      instance = klass.new({})
      expect(instance && instance[:secondary_key]).to be_nil
    end

    it 'warns about unrecognized keys' do
      instance = klass.new(secondary_key: 'x', bogus_setting: 'bad')
      expect(instance.config_warnings).not_to be_empty
      expect(instance.config_warnings.first[:type]).to eq :bogus_setting
    end

    it 'does not warn about recognized keys' do
      instance = klass.new(
        secondary_key: 'x',
        batch_trigger: { frequency: '1 hour' },
        prevent_migrations: true
      )
      expect(instance.config_warnings).to be_empty
    end
  end

  describe 'parse_config integration' do
    it 'wraps _configurations in a Configurations instance' do
      @dm.update!(options: <<~YAML)
        _configurations:
          secondary_key: alt_id
        default:
          label: Test
      YAML
      @dm.reload
      @dm.option_configs force: true

      expect(@dm.configurations).to be_a(klass)
      expect(@dm.configurations[:secondary_key]).to eq 'alt_id'
    end

    it 'supports dig on parsed configurations' do
      @dm.update!(options: <<~YAML)
        _configurations:
          batch_trigger:
            frequency: 1 hour
            limit: 50
        default:
          label: Test
      YAML
      @dm.reload
      @dm.option_configs force: true

      expect(@dm.configurations.dig(:batch_trigger, :frequency)).to eq '1 hour'
      expect(@dm.configurations.dig(:batch_trigger, :limit)).to eq 50
    end

    it 'returns blank Configurations when no _configurations defined' do
      @dm.update!(options: <<~YAML)
        default:
          label: No configs
      YAML
      @dm.reload
      @dm.option_configs force: true

      expect(@dm.configurations).to be_a(klass)
      expect(@dm.configurations).to be_blank
    end
  end
end
