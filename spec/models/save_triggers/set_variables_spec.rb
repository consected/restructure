# frozen_string_literal: true

# Tests for SaveTriggers::SetVariables - Issue #964
#
# This spec verifies the set_variables save trigger, which makes the
# set_variables dynamic definition configuration available as a save trigger.
# It follows the model of set_save_trigger_results, but uses name/value keys
# (matching the existing set_variables config format) and stores results
# accessible via {{variables.varname}} substitutions.
#
# Covers:
# - Setting simple literal values (name/value)
# - Setting values with substitutions (e.g. value: "{{field}}")
# - Setting object/hash values using the object: key
# - Conditional execution with if:
# - Multiple configurations in a single trigger
# - Error handling when name is missing
# - Registration in ValidSaveTriggers
# - Variables accessible to subsequent triggers via {{variables.varname}}
# - Dot-notation for nested keys (e.g. 'hash_var.key1')
# - Integration with config-level set_variables (both coexist)

require 'rails_helper'

RSpec.describe SaveTriggers::SetVariables, type: :model do
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

    # Set up activity log definition
    al_def = ActivityLog.find(ActivityLog::PlayerContactPhone.definition.id)

    ActivityLog.active.where(item_type: al_def.item_type).where.not(id: al_def.id).each do |oal|
      oal.current_admin = @admin
      oal.disable!
    end

    config = <<~ENDDEF
      set_var_trigger_test_1:
        label: Set Var Trigger Test 1
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
    setup_access :activity_log__player_contact_phone__set_var_trigger_test_1, resource_type: :activity_log_type,
                                                                              access: :create, user: @user
    al_def.add_master_association

    @al = @player_contact.activity_log__player_contact_phones.create!(
      select_call_direction: 'from player',
      select_who: 'test user',
      extra_log_type: 'set_var_trigger_test_1'
    )

    @al.save_trigger_results = {}
    @al.trigger_variables = {}
  end

  describe 'setting simple values' do
    it 'sets a literal string value using name/value keys' do
      config = {
        name: 'my_variable',
        value: 'hello world'
      }

      trigger = SaveTriggers::SetVariables.new(config, @al)
      result = trigger.perform

      expect(result).to be_an(Array)
      expect(result.first[:name]).to eq 'my_variable'
      expect(result.first[:value]).to eq 'hello world'
      expect(@al.trigger_variables[:my_variable]).to eq 'hello world'
    end

    it 'sets a literal numeric value' do
      config = {
        name: 'numeric_var',
        value: 123
      }

      trigger = SaveTriggers::SetVariables.new(config, @al)
      trigger.perform

      expect(@al.trigger_variables[:numeric_var]).to eq 123
    end

    it 'sets a nil value when value is nil' do
      config = {
        name: 'nil_var',
        value: nil
      }

      trigger = SaveTriggers::SetVariables.new(config, @al)
      trigger.perform

      expect(@al.trigger_variables).to have_key(:nil_var)
      expect(@al.trigger_variables[:nil_var]).to be_nil
    end
  end

  describe 'setting values with substitutions' do
    it 'substitutes item attributes in the value' do
      config = {
        name: 'master_ref',
        value: '{{master_id}}'
      }

      trigger = SaveTriggers::SetVariables.new(config, @al)
      trigger.perform

      expect(@al.trigger_variables[:master_ref]).to eq @al.master_id.to_s
    end

    it 'substitutes multiple attributes in the value' do
      config = {
        name: 'combined',
        value: 'master-{{master_id}}-id-{{id}}'
      }

      trigger = SaveTriggers::SetVariables.new(config, @al)
      trigger.perform

      expected = "master-#{@al.master_id}-id-#{@al.id}"
      expect(@al.trigger_variables[:combined]).to eq expected
    end
  end

  describe 'setting object values' do
    it 'sets a hash value using object: key' do
      config = {
        name: 'hash_variable',
        value: {
          object: {
            id: '{{master_id}}',
            label: 'test'
          }
        }
      }

      trigger = SaveTriggers::SetVariables.new(config, @al)
      trigger.perform

      result = @al.trigger_variables[:hash_variable]
      expect(result).to be_a(Hash)
      expect(result[:id]).to eq @al.master_id.to_s
      expect(result[:label]).to eq 'test'
    end
  end

  describe 'dot-notation for nested keys' do
    it 'sets a nested key using dot-notation' do
      # First set the parent hash
      @al.trigger_variables[:hash_var] = { existing_key: 'existing_value' }

      config = {
        name: 'hash_var.new_key',
        value: 'nested value'
      }

      trigger = SaveTriggers::SetVariables.new(config, @al)
      trigger.perform

      expect(@al.trigger_variables[:hash_var][:new_key]).to eq 'nested value'
      # Existing keys should be preserved
      expect(@al.trigger_variables[:hash_var][:existing_key]).to eq 'existing_value'
    end

    it 'creates intermediate hashes for dot-notation' do
      config = {
        name: 'new_hash.deep_key',
        value: 'deep value'
      }

      trigger = SaveTriggers::SetVariables.new(config, @al)
      trigger.perform

      expect(@al.trigger_variables[:new_hash]).to be_a(Hash)
      expect(@al.trigger_variables[:new_hash][:deep_key]).to eq 'deep value'
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
        name: 'conditional_var',
        value: 'condition was met'
      }

      trigger = SaveTriggers::SetVariables.new(config, @al)
      trigger.perform

      expect(@al.trigger_variables[:conditional_var]).to eq 'condition was met'
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
        name: 'conditional_var',
        value: 'should not be set'
      }

      trigger = SaveTriggers::SetVariables.new(config, @al)
      result = trigger.perform

      expect(result).to be_empty
      expect(@al.trigger_variables).not_to have_key(:conditional_var)
    end
  end

  describe 'multiple configurations' do
    it 'processes multiple set_variables configurations' do
      config = [
        { name: 'var1', value: 'value1' },
        { name: 'var2', value: 42 }
      ]

      trigger = SaveTriggers::SetVariables.new(config, @al)
      result = trigger.perform

      expect(result.length).to eq 2
      expect(@al.trigger_variables[:var1]).to eq 'value1'
      expect(@al.trigger_variables[:var2]).to eq 42
    end
  end

  describe 'error handling' do
    it 'raises an error when name is missing' do
      config = {
        value: 'some value'
      }

      trigger = SaveTriggers::SetVariables.new(config, @al)
      expect { trigger.perform }.to raise_error(FphsException, /name to be specified/)
    end

    it 'raises an error when name is blank' do
      config = {
        name: '',
        value: 'some value'
      }

      trigger = SaveTriggers::SetVariables.new(config, @al)
      expect { trigger.perform }.to raise_error(FphsException, /name to be specified/)
    end
  end

  describe 'ValidSaveTriggers registration' do
    it 'is included in ValidSaveTriggers' do
      expect(OptionConfigs::ExtraOptionImplementers::SaveTriggers::ValidSaveTriggers).to include(:set_variables)
    end

    it 'can be resolved via trigger_class' do
      klass = OptionConfigs::ExtraOptions.trigger_class(:set_variables)
      expect(klass).to eq SaveTriggers::SetVariables
    end
  end

  describe 'integration with substitutions' do
    it 'makes variables accessible via {{variables.varname}} substitutions' do
      config = {
        name: 'trigger_var',
        value: 'from trigger'
      }

      trigger = SaveTriggers::SetVariables.new(config, @al)
      trigger.perform

      # Now verify the variable is accessible via substitution
      text = '{{variables.trigger_var}}'
      result = Formatter::Substitution.substitute(text, data: @al, tag_subs: nil)
      expect(result).to include('from trigger')
    end

    it 'allows a second trigger to reference variables set by the first' do
      # First trigger sets a value
      first_config = {
        name: 'step_one',
        value: '{{master_id}}'
      }

      SaveTriggers::SetVariables.new(first_config, @al).perform
      expect(@al.trigger_variables[:step_one]).to eq @al.master_id.to_s

      # Second trigger reads the value via substitution
      second_config = {
        name: 'step_two',
        value: '{{variables.step_one}}'
      }

      SaveTriggers::SetVariables.new(second_config, @al).perform
      expect(@al.trigger_variables[:step_two]).to eq @al.master_id.to_s
    end

    it 'makes hash variable values accessible with dot-notation in substitutions' do
      config = {
        name: 'config_hash',
        value: {
          object: {
            key1: 'value1',
            key2: 'value2'
          }
        }
      }

      trigger = SaveTriggers::SetVariables.new(config, @al)
      trigger.perform

      text = '{{variables.config_hash.key1}}'
      result = Formatter::Substitution.substitute(text, data: @al, tag_subs: nil)
      expect(result).to include('value1')
    end

    it 'coexists with config-level set_variables from option_type_config' do
      # Set up an activity log config that has set_variables at the config level
      al_def = ActivityLog.find(ActivityLog::PlayerContactPhone.definition.id)
      al_def.extra_log_types = <<~YAML
        set_var_trigger_test_1:
          label: Set Var Trigger Test 1
          fields:
            - select_call_direction
            - select_who
          set_variables:
            - name: config_var
              value: from config
          caption_before:
            all_fields: '{{variables.config_var}} and {{variables.trigger_var}}'
      YAML
      al_def.current_admin = @admin
      al_def.force_regenerate = true
      al_def.updated_at = DateTime.now
      al_def.save!
      ActivityLog.refresh_outdated
      al_def.reload
      al_def.force_option_config_parse
      al_def.add_master_association

      @al.reload
      @al.current_user = @user

      # Set a variable via the trigger
      trigger_config = { name: 'trigger_var', value: 'from trigger' }
      SaveTriggers::SetVariables.new(trigger_config, @al).perform

      # Both config-level and trigger-level variables should be accessible
      caption = @al.extra_log_type_config.caption_before[:all_fields][:caption]
      result = Formatter::Substitution.substitute(caption, data: @al, tag_subs: nil)

      expect(result).to include('from config')
      expect(result).to include('from trigger')
    end
  end
end
