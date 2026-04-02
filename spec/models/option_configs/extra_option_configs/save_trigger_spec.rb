# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for SaveTrigger configuration class.
# Verifies TriggerTasks typed attributes, on_save cascade,
# validate callbacks, and integration through ExtraOptions
# initialization (clean_save_triggers behavior).
RSpec.describe 'ExtraOptionConfigs::SaveTrigger', type: :model do
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

  let(:klass) { OptionConfigs::ExtraOptionConfigs::SaveTrigger }

  describe 'class structure' do
    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares all trigger keys as typed attributes with TriggerTasks type' do
      %i[on_create on_update on_save on_upload on_disable before_save].each do |key|
        expect(klass.option_types[:typed]).to include(key),
                                              "Expected option_types[:typed] to include :#{key}"
        expect(klass.typed_attribute_types[key]).to eq(OptionConfigs::ExtraOptionConfigs::TriggerTasks),
                                                    "Expected typed_attribute_types[:#{key}] to be TriggerTasks"
      end
    end
  end

  describe 'initialization' do
    it 'initializes trigger keys as TriggerTasks instances' do
      instance = klass.new(on_create: [{ notify: { type: 'email' } }])
      expect(instance.on_create).to be_a(OptionConfigs::ExtraOptionConfigs::TriggerTasks)
      expect(instance.on_create.tasks).to eq([{ notify: { type: 'email' } }])
    end

    it 'defaults missing trigger keys to blank TriggerTasks' do
      instance = klass.new({})
      expect(instance.on_create).to be_a(OptionConfigs::ExtraOptionConfigs::TriggerTasks)
      expect(instance.on_create).to be_blank
      expect(instance.on_upload).to be_a(OptionConfigs::ExtraOptionConfigs::TriggerTasks)
      expect(instance.on_upload).to be_blank
    end

    it 'supports hash-like bracket access for trigger keys' do
      instance = klass.new(on_create: [{ notify: { type: 'email' } }])
      expect(instance[:on_create]).to be_a(Array)
    end

    it 'cascades on_save into on_create and on_update' do
      instance = klass.new(on_save: { notify: { type: 'email' } })
      expect(instance.on_create.tasks).to be_an Array
      expect(instance.on_create.tasks.length).to eq 1
      expect(instance.on_update.tasks).to be_an Array
      expect(instance.on_update.tasks.length).to eq 1
    end

    it 'appends on_save to existing on_create and on_update' do
      instance = klass.new(
        on_save: { notify: { type: 'email' } },
        on_create: { create_action: { type: 'special' } }
      )
      expect(instance.on_create.tasks).to be_an Array
      expect(instance.on_create.tasks.length).to eq 2
      expect(instance.on_update.tasks).to be_an Array
      expect(instance.on_update.tasks.length).to eq 1
    end

    it 'returns blank when initialized with empty hash' do
      instance = klass.new({})
      expect(instance).to be_blank
    end
  end

  describe 'validate callbacks' do
    it 'validates keys against ValidSaveTriggerTriggers' do
      instance = klass.new(on_invalid_trigger: { something: true })
      expect(instance.config_errors).not_to be_empty
      err = instance.config_errors.find { |e| e[:type] == :save_trigger }
      expect(err).to be_present
    end

    it 'with invalid keys has errors on :save_trigger' do
      instance = klass.new(on_invalid_trigger: { something: true })
      expect(instance.config_errors).not_to be_empty
      err = instance.config_errors.find { |e| e[:type] == :save_trigger }
      expect(err).to be_present
      expect(err[:message]).to match(/invalid keys/)
    end

    it 'with valid keys has no validation errors' do
      instance = klass.new(on_create: [{ notify: { type: 'email' } }])
      expect(instance.config_errors).to be_empty
    end

    it 'with invalid keys has ActiveModel errors' do
      instance = klass.new(on_invalid_trigger: { something: true })
      expect(instance.errors[:save_trigger]).not_to be_empty
    end
  end

  describe 'ExtraOptions integration' do
    it 'defaults save_trigger to a SaveTrigger with blank TriggerTasks' do
      eo = config_for(<<~YAML)
        default:
          label: No save triggers
      YAML

      expect(eo.save_trigger).to be_a OptionConfigs::ExtraOptionConfigs::SaveTrigger
      expect(eo.save_trigger[:on_upload]).to be_a Hash
      expect(eo.save_trigger[:on_upload]).to be_blank
      expect(eo.save_trigger[:on_disable]).to be_a Hash
      expect(eo.save_trigger[:on_disable]).to be_blank
    end

    it 'cascades on_save to on_create and on_update as array defaults' do
      eo = config_for(<<~YAML)
        default:
          save_trigger:
            on_save:
              notify:
                type: email
      YAML

      expect(eo.save_trigger[:on_create]).to be_an Array
      expect(eo.save_trigger[:on_update]).to be_an Array
      expect(eo.save_trigger[:on_create].length).to eq 1
      expect(eo.save_trigger[:on_update].length).to eq 1
    end

    it 'appends on_save triggers to existing on_create and on_update' do
      eo = config_for(<<~YAML)
        default:
          save_trigger:
            on_save:
              notify:
                type: email
            on_create:
              create_action:
                type: special
      YAML

      expect(eo.save_trigger[:on_create]).to be_an Array
      expect(eo.save_trigger[:on_create].length).to eq 2
      expect(eo.save_trigger[:on_update]).to be_an Array
      expect(eo.save_trigger[:on_update].length).to eq 1
    end

    it 'reports an error for invalid trigger keys' do
      eo = config_for(<<~YAML)
        default:
          save_trigger:
            on_invalid_trigger:
              something: true
      YAML

      expect(eo.config_errors).not_to be_empty
      err = eo.config_errors.find { |e| e[:type] == :save_trigger }
      expect(err).to be_present
    end

    it 'symbolizes save_trigger keys' do
      eo = config_for(<<~YAML)
        default:
          save_trigger:
            on_save:
              notify:
                type: email
      YAML
      expect(eo.save_trigger).to be_a OptionConfigs::ExtraOptionConfigs::SaveTrigger
      expect(eo.save_trigger.on_create).to be_a OptionConfigs::ExtraOptionConfigs::TriggerTasks
    end

    it 'is stored directly as a SaveTrigger instance' do
      eo = config_for(<<~YAML)
        default:
          save_trigger:
            on_save:
              notify:
                type: email
      YAML

      expect(eo.save_trigger).to be_a OptionConfigs::ExtraOptionConfigs::SaveTrigger
      expect(eo.save_trigger[:on_create]).to be_a Array
    end
  end
end
