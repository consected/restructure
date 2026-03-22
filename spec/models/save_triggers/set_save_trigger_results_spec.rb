# frozen_string_literal: true

# Tests for SaveTriggers::SetSaveTriggerResults - Issue #949
#
# This spec verifies the set_save_trigger_results save trigger, which allows
# explicitly setting values in save_trigger_results for use by subsequent
# triggers in substitutions and conditional actions.
#
# Covers:
# - Setting simple literal values
# - Setting values with substitutions ({{field}})
# - Setting object/hash values using the object: key
# - Dot-notation for nested keys (e.g. 'hash_var.key1')
# - Conditional execution with if:
# - Multiple configurations in a single trigger
# - Named configuration format
# - Error handling when element is missing
# - Registration in ValidSaveTriggers

require 'rails_helper'

RSpec.describe SaveTriggers::SetSaveTriggerResults, type: :model do
  include ModelSupport
  include PlayerContactSupport

  before :each do
    create_user
    setup_access :player_contacts
    let_user_create_player_contacts
    create_item(data: rand(10_000_000_000_000_000), rank: 10)
    @player_contact.master.current_user = @user
    @master = @player_contact.master
    expect(@master).not_to be nil

    # Set up activity log definition with save_trigger_results support
    al_def = ActivityLog.find(ActivityLog::PlayerContactPhone.definition.id)

    ActivityLog.active.where(item_type: al_def.item_type).where.not(id: al_def.id).each do |oal|
      oal.current_admin = @admin
      oal.disable!
    end

    config = <<~ENDDEF
      set_str_test_1:
        label: Set STR Test 1
        fields:
          - select_call_direction
          - select_who
    ENDDEF

    al_def.extra_log_types = config
    al_def.current_admin = @admin
    al_def.force_regenerate = true
    al_def.updated_at = DateTime.now
    al_def.save!
    ActivityLog.refresh_outdated
    al_def.reload
    al_def.force_option_config_parse

    setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
    setup_access :activity_log__player_contact_phone__set_str_test_1, resource_type: :activity_log_type,
                                                                      access: :create, user: @user
    al_def.add_master_association

    @al = @player_contact.activity_log__player_contact_phones.create!(
      select_call_direction: 'from player',
      select_who: 'test user',
      extra_log_type: 'set_str_test_1'
    )

    @al.save_trigger_results = {}
  end

  describe 'setting simple values' do
    it 'sets a literal string value' do
      config = {
        element: 'my_variable',
        value: 'hello world'
      }

      trigger = SaveTriggers::SetSaveTriggerResults.new(config, @al)
      result = trigger.perform

      expect(result).to be_an(Array)
      expect(result.first[:element]).to eq 'my_variable'
      expect(result.first[:value]).to eq 'hello world'
      expect(@al.save_trigger_results['my_variable']).to eq 'hello world'
    end

    it 'sets a literal numeric value' do
      config = {
        element: 'numeric_var',
        value: 123
      }

      trigger = SaveTriggers::SetSaveTriggerResults.new(config, @al)
      trigger.perform

      expect(@al.save_trigger_results['numeric_var']).to eq 123
    end

    it 'sets a nil value when value is not specified' do
      config = {
        element: 'nil_var',
        value: nil
      }

      trigger = SaveTriggers::SetSaveTriggerResults.new(config, @al)
      trigger.perform

      expect(@al.save_trigger_results).to have_key('nil_var')
      expect(@al.save_trigger_results['nil_var']).to be_nil
    end
  end

  describe 'setting values with substitutions' do
    it 'substitutes item attributes in the value' do
      config = {
        element: 'master_ref',
        value: '{{master_id}}'
      }

      trigger = SaveTriggers::SetSaveTriggerResults.new(config, @al)
      trigger.perform

      expect(@al.save_trigger_results['master_ref']).to eq @al.master_id.to_s
    end

    it 'substitutes multiple attributes in the value' do
      config = {
        element: 'combined',
        value: 'master-{{master_id}}-id-{{id}}'
      }

      trigger = SaveTriggers::SetSaveTriggerResults.new(config, @al)
      trigger.perform

      expected = "master-#{@al.master_id}-id-#{@al.id}"
      expect(@al.save_trigger_results['combined']).to eq expected
    end
  end

  describe 'setting object values' do
    it 'sets a hash value using object: key' do
      config = {
        element: 'hash_variable',
        value: {
          object: {
            id: '{{master_id}}',
            name: 'test'
          }
        }
      }

      trigger = SaveTriggers::SetSaveTriggerResults.new(config, @al)
      trigger.perform

      result = @al.save_trigger_results['hash_variable']
      expect(result).to be_a(Hash)
      expect(result[:id]).to eq @al.master_id.to_s
      expect(result[:name]).to eq 'test'
    end
  end

  describe 'dot-notation for nested keys' do
    it 'sets a nested key using dot-notation' do
      # First set the parent hash
      @al.save_trigger_results['hash_var'] = { 'existing_key' => 'existing_value' }

      config = {
        element: 'hash_var.new_key',
        value: 'nested value'
      }

      trigger = SaveTriggers::SetSaveTriggerResults.new(config, @al)
      trigger.perform

      expect(@al.save_trigger_results['hash_var']['new_key']).to eq 'nested value'
      # Existing keys should be preserved
      expect(@al.save_trigger_results['hash_var']['existing_key']).to eq 'existing_value'
    end

    it 'creates intermediate hashes for dot-notation' do
      config = {
        element: 'new_hash.deep_key',
        value: 'deep value'
      }

      trigger = SaveTriggers::SetSaveTriggerResults.new(config, @al)
      trigger.perform

      expect(@al.save_trigger_results['new_hash']).to be_a(Hash)
      expect(@al.save_trigger_results['new_hash']['deep_key']).to eq 'deep value'
    end

    it 'handles multiple dot levels' do
      config = {
        element: 'level1.level2.level3',
        value: 'deeply nested'
      }

      trigger = SaveTriggers::SetSaveTriggerResults.new(config, @al)
      trigger.perform

      expect(@al.save_trigger_results['level1']['level2']['level3']).to eq 'deeply nested'
    end
  end

  describe 'conditional execution' do
    it 'sets value when if condition is met' do
      config = {
        if: {
          all: {
            this: {
              select_call_direction: 'from player'
            }
          }
        },
        element: 'conditional_var',
        value: 'condition was met'
      }

      trigger = SaveTriggers::SetSaveTriggerResults.new(config, @al)
      trigger.perform

      expect(@al.save_trigger_results['conditional_var']).to eq 'condition was met'
    end

    it 'skips setting value when if condition is not met' do
      config = {
        if: {
          all: {
            this: {
              select_call_direction: 'nonexistent value'
            }
          }
        },
        element: 'conditional_var',
        value: 'should not be set'
      }

      trigger = SaveTriggers::SetSaveTriggerResults.new(config, @al)
      result = trigger.perform

      expect(result).to be_empty
      expect(@al.save_trigger_results).not_to have_key('conditional_var')
    end
  end

  describe 'multiple configurations' do
    it 'processes multiple set_save_trigger_results configurations' do
      config = [
        { element: 'var1', value: 'value1' },
        { element: 'var2', value: 42 }
      ]

      trigger = SaveTriggers::SetSaveTriggerResults.new(config, @al)
      result = trigger.perform

      expect(result.length).to eq 2
      expect(@al.save_trigger_results['var1']).to eq 'value1'
      expect(@al.save_trigger_results['var2']).to eq 42
    end

    it 'processes named configuration format' do
      config = [
        { first_set: { element: 'named_var1', value: 'named_value1' } },
        { second_set: { element: 'named_var2', value: 'named_value2' } }
      ]

      trigger = SaveTriggers::SetSaveTriggerResults.new(config, @al)
      trigger.perform

      expect(@al.save_trigger_results['named_var1']).to eq 'named_value1'
      expect(@al.save_trigger_results['named_var2']).to eq 'named_value2'
    end
  end

  describe 'error handling' do
    it 'raises an error when element is missing' do
      config = {
        value: 'some value'
      }

      trigger = SaveTriggers::SetSaveTriggerResults.new(config, @al)
      expect { trigger.perform }.to raise_error(FphsException, /element to be specified/)
    end

    it 'raises an error when element is blank' do
      config = {
        element: '',
        value: 'some value'
      }

      trigger = SaveTriggers::SetSaveTriggerResults.new(config, @al)
      expect { trigger.perform }.to raise_error(FphsException, /element to be specified/)
    end
  end

  describe 'ValidSaveTriggers registration' do
    it 'is included in ValidSaveTriggers' do
      expect(OptionConfigs::ExtraOptionImplementers::SaveTriggers::ValidSaveTriggers).to include(:set_save_trigger_results)
    end

    it 'can be resolved via trigger_class' do
      klass = OptionConfigs::ExtraOptions.trigger_class(:set_save_trigger_results)
      expect(klass).to eq SaveTriggers::SetSaveTriggerResults
    end
  end

  describe 'integration with subsequent triggers' do
    it 'allows a second trigger to reference values set by the first' do
      # First trigger sets a value
      first_config = {
        element: 'step_one_result',
        value: '{{master_id}}'
      }

      SaveTriggers::SetSaveTriggerResults.new(first_config, @al).perform
      expect(@al.save_trigger_results['step_one_result']).to eq @al.master_id.to_s

      # Second trigger reads the value set by the first via substitution
      second_config = {
        element: 'step_two_result',
        value: '{{save_trigger_results.step_one_result}}'
      }

      SaveTriggers::SetSaveTriggerResults.new(second_config, @al).perform
      expect(@al.save_trigger_results['step_two_result']).to eq @al.master_id.to_s
    end
  end
end
