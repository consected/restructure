# frozen_string_literal: true

require 'rails_helper'

# Tests for OptionConfigs::TriggerTypes::Base — the base class for per-trigger-type
# descriptor classes. Verifies the DSL (pattern, allowed_keys, key_type), the registry
# (Base.for, Base.registered_types), and universal key inclusion across all non-delegate
# trigger types.
#
# These tests drive the implementation of issue #1058: refactoring hardcoded constant-based
# trigger validation into a proper class hierarchy under OptionConfigs::TriggerTypes.
RSpec.describe 'OptionConfigs::TriggerTypes::Base', type: :model do
  let(:base) { OptionConfigs::TriggerTypes::Base }

  describe 'registry lookup via .for' do
    it 'returns Notify class for :notify' do
      expect(base.for(:notify)).to eq(OptionConfigs::TriggerTypes::Notify)
    end

    it 'returns ChangeUserRoles class for :change_user_roles' do
      expect(base.for(:change_user_roles)).to eq(OptionConfigs::TriggerTypes::ChangeUserRoles)
    end

    it 'returns Transaction class for :transaction' do
      expect(base.for(:transaction)).to eq(OptionConfigs::TriggerTypes::Transaction)
    end

    it 'returns nil for an unknown trigger name' do
      expect(base.for(:unknown_trigger_type)).to be_nil
    end

    it 'accepts string keys and converts to symbol' do
      expect(base.for('notify')).to eq(OptionConfigs::TriggerTypes::Notify)
    end
  end

  describe '.registered_types' do
    let(:expected_types) do
      %i[
        change_user_roles set_item_flags create_filestore_container reload_this
        notify create_reference update_reference update_this add_tracker
        pull_external_data pull_emails run_batch_trigger set_save_trigger_results set_variables
        log generate_document redcap_request create_master full_text_search
        transaction background case
      ]
    end

    it 'includes all 22 trigger types' do
      expect(base.registered_types.keys).to match_array(expected_types)
    end

    it 'maps each key to a class that inherits from Base' do
      base.registered_types.each_value do |klass|
        expect(klass.ancestors).to include(base),
                                   "Expected #{klass} to inherit from #{base}"
      end
    end
  end

  describe 'pattern classification' do
    it 'direct-config types return :direct_config pattern' do
      %i[change_user_roles set_item_flags create_filestore_container reload_this notify log create_master].each do |name|
        expect(base.for(name).pattern).to eq(:direct_config),
                                          "Expected #{name} to have :direct_config pattern"
      end
    end

    it 'named-entry types return :named_entry pattern' do
      named = %i[
        create_reference update_reference update_this add_tracker
        pull_external_data run_batch_trigger set_save_trigger_results set_variables
        generate_document redcap_request full_text_search
      ]
      named.each do |name|
        expect(base.for(name).pattern).to eq(:named_entry),
                                          "Expected #{name} to have :named_entry pattern"
      end
    end

    it 'delegate types return :delegate pattern' do
      %i[transaction background case].each do |name|
        expect(base.for(name).pattern).to eq(:delegate),
                                          "Expected #{name} to have :delegate pattern"
      end
    end
  end

  describe 'universal keys' do
    let(:universal_keys) { %i[if on_complete on_failure] }

    it 'all direct-config types include universal keys in allowed_keys' do
      %i[change_user_roles set_item_flags create_filestore_container reload_this notify log create_master].each do |name|
        type_class = base.for(name)
        universal_keys.each do |key|
          expect(type_class.allowed_keys).to include(key),
                                             "Expected #{name} allowed_keys to include :#{key}"
        end
      end
    end

    it 'all named-entry types include universal keys in allowed_keys' do
      named = %i[
        create_reference update_reference update_this add_tracker
        pull_external_data run_batch_trigger set_save_trigger_results set_variables
        generate_document redcap_request full_text_search
      ]
      named.each do |name|
        type_class = base.for(name)
        universal_keys.each do |key|
          expect(type_class.allowed_keys).to include(key),
                                             "Expected #{name} allowed_keys to include :#{key}"
        end
      end
    end

    it 'delegate types do not declare allowed_keys' do
      %i[transaction background case].each do |name|
        type_class = base.for(name)
        expect(type_class.allowed_keys).to be_nil.or(be_empty),
                                           "Expected #{name} to have no allowed_keys"
      end
    end
  end

  describe 'nil value handling' do
    it 'does not warn when a typed key is present with a nil value (empty YAML key)' do
      # YAML `extra_substitutions:` (no value) parses as nil, which is semantically
      # equivalent to the key being absent — the runtime handles nil fine.
      type_class = base.for(:notify)
      config = { type: 'email', extra_substitutions: nil }
      warnings = type_class.validate_config(config)
      expect(warnings).to be_empty
    end

    it 'does not warn for nil on any key type (hash, array, boolean, string)' do
      # Use notify (direct-config) with nil values on keys of various declared types:
      # :hash (if, from_user_email), :hash_or_array (on_complete), :boolean (ignore_no_recipients),
      # :string_or_hash (type, subject), :array (attachments)
      type_class = base.for(:notify)
      config = {
        type: nil,
        subject: nil,
        ignore_no_recipients: nil,
        attachments: nil,
        from_user_email: nil,
        if: nil,
        on_complete: nil
      }
      warnings = type_class.validate_config(config)
      expect(warnings).to be_empty
    end
  end

  describe 'key type coverage' do
    it 'all non-delegate types declare key_type rules for every allowed key' do
      base.registered_types.each do |name, type_class|
        next if type_class.pattern == :delegate

        expect(type_class.allowed_keys).to be_present,
                                           "Expected #{name} to define allowed_keys"

        missing = type_class.allowed_keys - type_class.key_type_rules.keys
        expect(missing).to be_empty,
                           "Expected #{name} to define key_type rules for keys #{missing}"
      end
    end
  end
end
