# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for Configurations class (top-level _configurations options).
# Verifies Hash-like access ([], dig, reject, key?), recognized key warnings,
# value type validation (booleans, strings, arrays, nested hashes),
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

  describe 'validate_configurations_shape' do
    describe 'boolean keys' do
      it 'accepts true values' do
        instance = klass.new(use_current_version: true, prevent_migrations: true)
        instance.valid?
        expect(instance.errors).to be_empty
      end

      it 'accepts false values' do
        instance = klass.new(can_change_master: false, no_user_id: false)
        instance.valid?
        expect(instance.errors).to be_empty
      end

      it 'rejects string values for boolean keys' do
        instance = klass.new(prevent_migrations: 'yes')
        instance.valid?
        expect(instance.errors.full_messages.join).to include('prevent_migrations must be true or false')
      end

      it 'rejects integer values for boolean keys' do
        instance = klass.new(use_current_version: 1)
        instance.valid?
        expect(instance.errors.full_messages.join).to include('use_current_version must be true or false')
      end
    end

    describe 'string keys' do
      it 'accepts string values' do
        instance = klass.new(secondary_key: 'alt_id', tab_caption: 'My Tab')
        instance.valid?
        expect(instance.errors).to be_empty
      end

      it 'accepts symbol values' do
        instance = klass.new(secondary_key: :alt_id)
        instance.valid?
        expect(instance.errors).to be_empty
      end

      it 'rejects non-string values for string keys' do
        instance = klass.new(secondary_key: 123)
        instance.valid?
        expect(instance.errors.full_messages.join).to include('secondary_key must be a string')
      end

      it 'rejects hash values for string keys' do
        instance = klass.new(view_sql: { query: 'SELECT 1' })
        instance.valid?
        expect(instance.errors.full_messages.join).to include('view_sql must be a string')
      end

      it 'validates option_type_attr_name as a string key' do
        instance = klass.new(option_type_attr_name: 42)
        instance.valid?
        expect(instance.errors.full_messages.join).to include('option_type_attr_name must be a string')
      end

      it 'validates default_option_type_name as a string key' do
        instance = klass.new(default_option_type_name: true)
        instance.valid?
        expect(instance.errors.full_messages.join).to include('default_option_type_name must be a string')
      end
    end

    describe 'uniqueness_fields' do
      it 'accepts a string value' do
        instance = klass.new(uniqueness_fields: 'email')
        instance.valid?
        expect(instance.errors).to be_empty
      end

      it 'accepts an array of strings' do
        instance = klass.new(uniqueness_fields: %w[email name])
        instance.valid?
        expect(instance.errors).to be_empty
      end

      it 'rejects numeric values' do
        instance = klass.new(uniqueness_fields: 42)
        instance.valid?
        expect(instance.errors.full_messages.join).to include('uniqueness_fields must be a string or array of strings')
      end

      it 'rejects arrays containing non-strings' do
        instance = klass.new(uniqueness_fields: ['email', 123])
        instance.valid?
        expect(instance.errors.full_messages.join).to include('uniqueness_fields must be a string or array of strings')
      end
    end

    describe 'batch_trigger' do
      it 'accepts a valid hash with recognized sub-keys' do
        instance = klass.new(batch_trigger: { frequency: '1 hour', limit: 100, user: 'bot@example.com' })
        instance.valid?
        expect(instance.errors).to be_empty
      end

      it 'rejects non-hash values' do
        instance = klass.new(batch_trigger: 'every hour')
        instance.valid?
        expect(instance.errors.full_messages.join).to include('batch_trigger must be a Hash')
      end

      it 'warns about unrecognized sub-keys' do
        instance = klass.new(batch_trigger: { frequency: '1 hour', bogus: 'bad' })
        expect(instance.config_warnings).not_to be_empty
        expect(instance.config_warnings.map { |w| w[:type] }).to include(:batch_trigger)
      end
    end

    describe 'combined valid configuration' do
      it 'passes validation with all recognized keys set correctly' do
        instance = klass.new(
          use_current_version: true,
          prevent_migrations: false,
          can_change_master: false,
          no_user_id: true,
          secondary_key: 'alt_id',
          view_sql: 'SELECT 1',
          tab_caption: 'My Tab',
          foreign_key_through_external_id: 'ext_id',
          option_type_attr_name: 'category',
          default_option_type_name: 'general',
          uniqueness_fields: %w[email name],
          batch_trigger: { frequency: '1 hour', limit: 50 }
        )
        instance.valid?
        expect(instance.errors).to be_empty
        expect(instance.config_warnings).to be_empty
      end
    end
  end
end
