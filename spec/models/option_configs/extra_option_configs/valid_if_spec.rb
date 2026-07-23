# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for ValidIf configuration class.
# Verifies on_save cascade, key validation against ValidValidIfTriggers,
# validate callbacks, and integration through ExtraOptions initialization
# (clean_valid_if_def behavior).
RSpec.describe 'ExtraOptionConfigs::ValidIf', type: :model do
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

  let(:klass) { OptionConfigs::ExtraOptionConfigs::ValidIf }

  describe 'class structure' do
    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares configure_direct with type :hash' do
      expect(klass.option_types[:direct]).to include(:valid_if)
    end
  end

  describe 'initialization' do
    it 'cascades on_save to on_create and on_update' do
      instance = klass.new(on_save: { all: { this: { test1: 'is not null' } } })
      expect(instance.valid_if[:on_create]).to eq(instance.valid_if[:on_save])
      expect(instance.valid_if[:on_update]).to eq(instance.valid_if[:on_save])
    end

    it 'returns blank when initialized with empty hash' do
      instance = klass.new({})
      expect(instance).to be_blank
    end

    it 'symbolizes keys for backward compatibility' do
      instance = klass.new(on_save: { always: true })
      expect(instance.symbolize_keys).to have_key(:on_save)
    end
  end

  describe 'validate callbacks' do
    it 'validates keys against ValidValidIfTriggers' do
      instance = klass.new(on_invalid_key: { always: true })
      expect(instance.config_errors).not_to be_empty
      err = instance.config_errors.find { |e| e[:type] == :valid_if }
      expect(err).to be_present
    end

    it 'with invalid keys has errors on :valid_if' do
      instance = klass.new(on_invalid_key: { always: true })
      expect(instance.config_errors).not_to be_empty
      err = instance.config_errors.find { |e| e[:type] == :valid_if }
      expect(err).to be_present
      expect(err[:message]).to match(/invalid keys/)
    end

    it 'with valid keys has no validation errors' do
      instance = klass.new(on_save: { all: { this: { field: 'is not null' } } })
      expect(instance.config_errors).to be_empty
    end

    it 'with invalid keys has ActiveModel errors' do
      instance = klass.new(on_invalid_key: { always: true })
      expect(instance.errors[:valid_if]).not_to be_empty
    end

    it 'reports an error when a trigger payload is not a hash' do
      instance = klass.new(on_save: 'bad')
      expect(instance.config_errors).not_to be_empty
      expect(instance.errors[:valid_if]).not_to be_empty
    end
  end

  describe 'ExtraOptions integration' do
    it 'defaults valid_if to a blank ValidIf when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No valid_if
      YAML
      expect(eo.valid_if).to be_a OptionConfigs::ExtraOptionConfigs::ValidIf
      expect(eo.valid_if).to be_blank
    end

    it 'cascades on_save to on_create and on_update as defaults' do
      eo = config_for(<<~YAML)
        default:
          valid_if:
            on_save:
              all:
                this:
                  test1: is not null
      YAML

      expect(eo.valid_if.valid_if[:on_save]).to be_present
      expect(eo.valid_if.valid_if[:on_create]).to eq eo.valid_if.valid_if[:on_save]
      expect(eo.valid_if.valid_if[:on_update]).to eq eo.valid_if.valid_if[:on_save]
    end

    it 'merges on_save into existing on_create and on_update' do
      eo = config_for(<<~YAML)
        default:
          valid_if:
            on_save:
              all:
                this:
                  test1: is not null
            on_create:
              all:
                this:
                  test2: is not null
      YAML

      expect(eo.valid_if.valid_if[:on_create]).to have_key(:all)
    end

    it 'reports an error for invalid trigger keys' do
      eo = config_for(<<~YAML)
        default:
          valid_if:
            on_invalid_key:
              always: true
      YAML

      expect(eo.config_errors).not_to be_empty
      err = eo.config_errors.find { |e| e[:type].to_s == 'valid_if' }
      expect(err).to be_present
    end

    it 'symbolizes valid_if keys' do
      eo = config_for(<<~YAML)
        default:
          valid_if:
            on_save:
              always: true
      YAML
      expect(eo.valid_if.valid_if.keys).to all(be_a Symbol)
    end

    it 'is stored directly as a ValidIf BaseConfiguration instance' do
      eo = config_for(<<~YAML)
        default:
          valid_if:
            on_save:
              all:
                this:
                  test1: is not null
      YAML

      expect(eo.valid_if).to be_a OptionConfigs::ExtraOptionConfigs::ValidIf
      expect(eo.valid_if[:on_create]).to be_present
    end
  end
end
