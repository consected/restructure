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

  before(:all) do
    set_up_extra_options_configs
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

    it 'reports an error when initialized with a scalar instead of a hash' do
      instance = klass.new('bad')
      expect(instance.config_errors).not_to be_empty
      expect(instance.errors[:save_trigger]).not_to be_empty
    end

    it 'reports an error when a trigger payload is not a hash or array' do
      instance = klass.new(on_create: 'bad')
      expect(instance.config_errors).not_to be_empty
      expect(instance.errors[:save_trigger]).not_to be_empty
    end
  end

  # Issue #1384 - pull_external_data, redcap_request and notify all perform a genuine
  # update of `this` (the record being saved), and create_reference with in: this/
  # referring_record needs this record's id - none of these work correctly from
  # before_save, since the record isn't persisted (or fully saved) yet at that point.
  describe 'before_save unsupported trigger warnings (issue #1384)' do
    it 'warns when pull_external_data is used within before_save' do
      instance = klass.new(before_save: { pull_external_data: { url: 'http://example.com' } })
      warning = instance.config_warnings.find { |w| w[:type] == :before_save }
      expect(warning).to be_present
      expect(warning[:message]).to match(/pull_external_data/)
    end

    it 'warns when redcap_request is used within before_save' do
      instance = klass.new(before_save: { redcap_request: { study: 'Q1', method: 'project' } })
      warning = instance.config_warnings.find { |w| w[:type] == :before_save }
      expect(warning).to be_present
      expect(warning[:message]).to match(/redcap_request/)
    end

    it 'warns when notify is used within before_save' do
      instance = klass.new(before_save: { notify: { role: 'admin' } })
      warning = instance.config_warnings.find { |w| w[:type] == :before_save }
      expect(warning).to be_present
      expect(warning[:message]).to match(/notify/)
    end

    it 'warns when create_reference with in: this is used within before_save' do
      instance = klass.new(before_save: { create_reference: { player_contacts: { in: 'this' } } })
      warning = instance.config_warnings.find { |w| w[:type] == :before_save }
      expect(warning).to be_present
      expect(warning[:message]).to match(/create_reference/)
    end

    it 'warns when create_reference with in: referring_record is used within before_save' do
      instance = klass.new(before_save: { create_reference: { player_contacts: { in: 'referring_record' } } })
      warning = instance.config_warnings.find { |w| w[:type] == :before_save }
      expect(warning).to be_present
    end

    it 'does not warn when create_reference with in: master is used within before_save' do
      instance = klass.new(before_save: { create_reference: { player_contacts: { in: 'master' } } })
      expect(instance.config_warnings).to be_empty
    end

    it 'still warns for a trigger nested inside a transaction within before_save' do
      instance = klass.new(before_save: { transaction: { notify: { role: 'admin' } } })
      warning = instance.config_warnings.find { |w| w[:type] == :before_save }
      expect(warning).to be_present
      expect(warning[:message]).to match(/notify/)
    end

    it 'does not warn when the same triggers are used within on_create' do
      instance = klass.new(on_create: { pull_external_data: { url: 'http://example.com' } })
      expect(instance.config_warnings).to be_empty
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
      err = eo.config_errors.find { |e| e[:type].to_s == 'save_trigger' }
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

    it 'normalizes nested create_reference trigger lists to plain hashes and arrays' do
      eo = config_for(<<~YAML)
        default:
          save_trigger:
            on_create:
              create_reference:
                - activity_log__play_ipa_assignment_inex_checklist:
                    in: master
                    with:
                      extra_log_type: phone_screen_review
                      force_create: true
                - activity_log__play_ipa_assignment:
                    if:
                      all:
                        embedded_item:
                          allow_future_comms_yes_no:
                            -
                            - ''
                            - 'no'
                      any:
                        embedded_item:
                          select_still_interested: 'no'
                          select_intro_interested: not interested
                    in: master
                    with:
                      extra_log_type: finalized_phone_screen
                    notify:
                      - type: email
                        role: email - inex pi
      YAML

      on_create = eo.save_trigger[:on_create]

      expect(on_create).to be_a(Hash)
      expect(on_create[:create_reference]).to be_an(Array)
      expect(on_create[:create_reference].first).to be_a(Hash)
      expect(on_create[:create_reference].first[:activity_log__play_ipa_assignment_inex_checklist]).to be_a(Hash)
      expect(on_create[:create_reference].last[:activity_log__play_ipa_assignment][:if]).to eq(
        all: {
          embedded_item: {
            allow_future_comms_yes_no: [nil, '', 'no']
          }
        },
        any: {
          embedded_item: {
            select_still_interested: 'no',
            select_intro_interested: 'not interested'
          }
        }
      )
      expect(on_create[:create_reference].last[:activity_log__play_ipa_assignment][:notify]).to be_an(Array)
      expect(on_create[:create_reference].last[:activity_log__play_ipa_assignment][:notify].first).to be_a(Hash)
    end
  end
end
