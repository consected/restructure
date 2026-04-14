# frozen_string_literal: true

require 'rails_helper'

# Tests for all 21 trigger type descriptor classes under OptionConfigs::TriggerTypes.
# Each trigger type declares its structural pattern (:direct_config, :named_entry, or :delegate),
# allowed configuration keys, and per-key type constraints.
#
# Also tests the validate_config interface that each type exposes, verifying:
# - Valid configs produce no warnings
# - Unrecognized keys produce warnings
# - Key type violations produce warnings
# - Delegate types skip key validation entirely
#
# These tests drive the implementation of issue #1058.
RSpec.describe 'OptionConfigs::TriggerTypes definitions', type: :model do
  let(:base) { OptionConfigs::TriggerTypes::Base }

  # ─── Direct-config types ──────────────────────────────────────────────

  describe 'ChangeUserRoles' do
    let(:type_class) { OptionConfigs::TriggerTypes::ChangeUserRoles }

    it 'inherits from Base' do
      expect(type_class.ancestors).to include(base)
    end

    it 'has :direct_config pattern' do
      expect(type_class.pattern).to eq(:direct_config)
    end

    it 'declares the expected allowed_keys' do
      expect(type_class.allowed_keys).to match_array(%i[if add_role_names remove_role_names on_complete on_failure])
    end

    it 'declares no key_type_rules' do
      expect(type_class.key_type_rules).to be_empty
    end
  end

  describe 'SetItemFlags' do
    let(:type_class) { OptionConfigs::TriggerTypes::SetItemFlags }

    it 'has :direct_config pattern' do
      expect(type_class.pattern).to eq(:direct_config)
    end

    it 'declares the expected allowed_keys' do
      expect(type_class.allowed_keys).to match_array(
        %i[first if force_not_editable_save flags add_flags remove_flags on_complete on_failure]
      )
    end

    it 'declares force_not_editable_save as :boolean' do
      expect(type_class.key_type_rules[:force_not_editable_save]).to eq(:boolean)
    end
  end

  describe 'CreateFilestoreContainer' do
    let(:type_class) { OptionConfigs::TriggerTypes::CreateFilestoreContainer }

    it 'has :direct_config pattern' do
      expect(type_class.pattern).to eq(:direct_config)
    end

    it 'declares the expected allowed_keys' do
      expect(type_class.allowed_keys).to match_array(
        %i[name label create_with_role if on_complete on_failure]
      )
    end

    it 'declares name, label, create_with_role as :string' do
      expect(type_class.key_type_rules[:name]).to eq(:string)
      expect(type_class.key_type_rules[:label]).to eq(:string)
      expect(type_class.key_type_rules[:create_with_role]).to eq(:string)
    end
  end

  describe 'ReloadThis' do
    let(:type_class) { OptionConfigs::TriggerTypes::ReloadThis }

    it 'has :direct_config pattern' do
      expect(type_class.pattern).to eq(:direct_config)
    end

    it 'declares only universal keys' do
      expect(type_class.allowed_keys).to match_array(%i[if on_complete on_failure])
    end

    it 'declares no key_type_rules' do
      expect(type_class.key_type_rules).to be_empty
    end
  end

  # ─── Named-entry types ────────────────────────────────────────────────

  describe 'Notify' do
    let(:type_class) { OptionConfigs::TriggerTypes::Notify }

    it 'has :named_entry pattern' do
      expect(type_class.pattern).to eq(:named_entry)
    end

    it 'declares the expected allowed_keys' do
      expected = %i[
        type role users emails phones phone_records list_type default_country_code
        from_user_email ignore_no_recipients layout_template content_template
        content_template_text subject calendar_invite attachments extra_substitutions
        importance when on_complete on_failure if app_type user
      ]
      expect(type_class.allowed_keys).to match_array(expected)
    end

    it 'declares type as :string and ignore_no_recipients as :boolean' do
      expect(type_class.key_type_rules[:type]).to eq(:string)
      expect(type_class.key_type_rules[:ignore_no_recipients]).to eq(:boolean)
    end
  end

  describe 'CreateReference' do
    let(:type_class) { OptionConfigs::TriggerTypes::CreateReference }

    it 'has :named_entry pattern' do
      expect(type_class.pattern).to eq(:named_entry)
    end

    it 'declares the expected allowed_keys' do
      expected = %i[if in force_create force_not_valid with_result with on_complete on_failure to_existing_record]
      expect(type_class.allowed_keys).to match_array(expected)
    end

    it 'declares force_create and force_not_valid as :boolean' do
      expect(type_class.key_type_rules[:force_create]).to eq(:boolean)
      expect(type_class.key_type_rules[:force_not_valid]).to eq(:boolean)
    end
  end

  describe 'UpdateReference' do
    let(:type_class) { OptionConfigs::TriggerTypes::UpdateReference }

    it 'has :named_entry pattern' do
      expect(type_class.pattern).to eq(:named_entry)
    end

    it 'declares the expected allowed_keys' do
      expected = %i[if first force_not_editable_save force_not_valid with_result with on_complete on_failure]
      expect(type_class.allowed_keys).to match_array(expected)
    end

    it 'declares force_not_editable_save and force_not_valid as :boolean' do
      expect(type_class.key_type_rules[:force_not_editable_save]).to eq(:boolean)
      expect(type_class.key_type_rules[:force_not_valid]).to eq(:boolean)
    end
  end

  describe 'UpdateThis' do
    let(:type_class) { OptionConfigs::TriggerTypes::UpdateThis }

    it 'has :named_entry pattern' do
      expect(type_class.pattern).to eq(:named_entry)
    end

    it 'declares the expected allowed_keys' do
      expected = %i[if force_not_editable_save force_not_valid with_result with on_complete on_failure]
      expect(type_class.allowed_keys).to match_array(expected)
    end

    it 'declares force_not_editable_save and force_not_valid as :boolean' do
      expect(type_class.key_type_rules[:force_not_editable_save]).to eq(:boolean)
      expect(type_class.key_type_rules[:force_not_valid]).to eq(:boolean)
    end
  end

  describe 'AddTracker' do
    let(:type_class) { OptionConfigs::TriggerTypes::AddTracker }

    it 'has :named_entry pattern' do
      expect(type_class.pattern).to eq(:named_entry)
    end

    it 'declares the expected allowed_keys' do
      expect(type_class.allowed_keys).to match_array(%i[if with on_complete on_failure])
    end

    it 'declares no key_type_rules' do
      expect(type_class.key_type_rules).to be_empty
    end
  end

  describe 'PullExternalData' do
    let(:type_class) { OptionConfigs::TriggerTypes::PullExternalData }

    it 'has :named_entry pattern' do
      expect(type_class.pattern).to eq(:named_entry)
    end

    it 'declares the expected allowed_keys' do
      expected = %i[
        if force_not_editable_save local_data data_field data_field_format
        response_code_field method from to post_data success_if on_complete on_failure
      ]
      expect(type_class.allowed_keys).to match_array(expected)
    end

    it 'declares force_not_editable_save as :boolean and method as :string' do
      expect(type_class.key_type_rules[:force_not_editable_save]).to eq(:boolean)
      expect(type_class.key_type_rules[:method]).to eq(:string)
    end
  end

  describe 'RunBatchTrigger' do
    let(:type_class) { OptionConfigs::TriggerTypes::RunBatchTrigger }

    it 'has :named_entry pattern' do
      expect(type_class.pattern).to eq(:named_entry)
    end

    it 'declares the expected allowed_keys' do
      expect(type_class.allowed_keys).to match_array(%i[if resource_name mode limit on_complete on_failure])
    end

    it 'declares resource_name and mode as :string and limit as :integer' do
      expect(type_class.key_type_rules[:resource_name]).to eq(:string)
      expect(type_class.key_type_rules[:mode]).to eq(:string)
      expect(type_class.key_type_rules[:limit]).to eq(:integer)
    end
  end

  describe 'SetSaveTriggerResults' do
    let(:type_class) { OptionConfigs::TriggerTypes::SetSaveTriggerResults }

    it 'has :named_entry pattern' do
      expect(type_class.pattern).to eq(:named_entry)
    end

    it 'declares the expected allowed_keys' do
      expect(type_class.allowed_keys).to match_array(%i[if element value on_complete on_failure])
    end

    it 'declares element as :string' do
      expect(type_class.key_type_rules[:element]).to eq(:string)
    end
  end

  describe 'SetVariables' do
    let(:type_class) { OptionConfigs::TriggerTypes::SetVariables }

    it 'has :named_entry pattern' do
      expect(type_class.pattern).to eq(:named_entry)
    end

    it 'declares the expected allowed_keys' do
      expect(type_class.allowed_keys).to match_array(%i[if name value on_complete on_failure])
    end

    it 'declares name as :string' do
      expect(type_class.key_type_rules[:name]).to eq(:string)
    end
  end

  describe 'Log' do
    let(:type_class) { OptionConfigs::TriggerTypes::Log }

    it 'has :named_entry pattern' do
      expect(type_class.pattern).to eq(:named_entry)
    end

    it 'declares the expected allowed_keys' do
      expect(type_class.allowed_keys).to match_array(%i[if message severity on_complete on_failure])
    end

    it 'declares message and severity as :string' do
      expect(type_class.key_type_rules[:message]).to eq(:string)
      expect(type_class.key_type_rules[:severity]).to eq(:string)
    end
  end

  describe 'GenerateDocument' do
    let(:type_class) { OptionConfigs::TriggerTypes::GenerateDocument }

    it 'has :named_entry pattern' do
      expect(type_class.pattern).to eq(:named_entry)
    end

    it 'declares the expected allowed_keys' do
      expected = %i[
        content_template_name content_template_text layout_template extra_substitutions
        container filename content_type path skip_existing replace
        store_as_user store_in_app_type if on_complete on_failure
      ]
      expect(type_class.allowed_keys).to match_array(expected)
    end

    it 'declares content_template_name and content_type as :string, skip_existing and replace as :boolean' do
      expect(type_class.key_type_rules[:content_template_name]).to eq(:string)
      expect(type_class.key_type_rules[:content_type]).to eq(:string)
      expect(type_class.key_type_rules[:skip_existing]).to eq(:boolean)
      expect(type_class.key_type_rules[:replace]).to eq(:boolean)
    end
  end

  describe 'RedcapRequest' do
    let(:type_class) { OptionConfigs::TriggerTypes::RedcapRequest }

    it 'has :named_entry pattern' do
      expect(type_class.pattern).to eq(:named_entry)
    end

    it 'declares the expected allowed_keys' do
      expected = %i[
        study project_name local_data method post_data success_if
        force_not_editable_save data_field data_field_format on_complete on_failure if
      ]
      expect(type_class.allowed_keys).to match_array(expected)
    end

    it 'declares study, project_name, method as :string and force_not_editable_save as :boolean' do
      expect(type_class.key_type_rules[:study]).to eq(:string)
      expect(type_class.key_type_rules[:project_name]).to eq(:string)
      expect(type_class.key_type_rules[:method]).to eq(:string)
      expect(type_class.key_type_rules[:force_not_editable_save]).to eq(:boolean)
    end
  end

  describe 'CreateMaster' do
    let(:type_class) { OptionConfigs::TriggerTypes::CreateMaster }

    it 'has :named_entry pattern' do
      expect(type_class.pattern).to eq(:named_entry)
    end

    it 'declares the expected allowed_keys' do
      expect(type_class.allowed_keys).to match_array(%i[if force_create move_this with on_complete on_failure])
    end

    it 'declares force_create and move_this as :boolean' do
      expect(type_class.key_type_rules[:force_create]).to eq(:boolean)
      expect(type_class.key_type_rules[:move_this]).to eq(:boolean)
    end
  end

  describe 'FullTextSearch' do
    let(:type_class) { OptionConfigs::TriggerTypes::FullTextSearch }

    it 'has :named_entry pattern' do
      expect(type_class.pattern).to eq(:named_entry)
    end

    it 'declares the expected allowed_keys' do
      expected = %i[source_fields target_column extra_content ts_config if on_complete on_failure]
      expect(type_class.allowed_keys).to match_array(expected)
    end

    it 'declares target_column and ts_config as :string' do
      expect(type_class.key_type_rules[:target_column]).to eq(:string)
      expect(type_class.key_type_rules[:ts_config]).to eq(:string)
    end
  end

  # ─── Delegate types ───────────────────────────────────────────────────

  describe 'Transaction' do
    let(:type_class) { OptionConfigs::TriggerTypes::Transaction }

    it 'has :delegate pattern' do
      expect(type_class.pattern).to eq(:delegate)
    end

    it 'declares no allowed_keys' do
      expect(type_class.allowed_keys).to be_nil.or(be_empty)
    end

    it 'declares no key_type_rules' do
      expect(type_class.key_type_rules).to be_empty
    end
  end

  describe 'Background' do
    let(:type_class) { OptionConfigs::TriggerTypes::Background }

    it 'has :delegate pattern' do
      expect(type_class.pattern).to eq(:delegate)
    end

    it 'declares no allowed_keys' do
      expect(type_class.allowed_keys).to be_nil.or(be_empty)
    end

    it 'declares no key_type_rules' do
      expect(type_class.key_type_rules).to be_empty
    end
  end

  describe 'Case' do
    let(:type_class) { OptionConfigs::TriggerTypes::Case }

    it 'has :delegate pattern' do
      expect(type_class.pattern).to eq(:delegate)
    end

    it 'declares no allowed_keys' do
      expect(type_class.allowed_keys).to be_nil.or(be_empty)
    end

    it 'declares no key_type_rules' do
      expect(type_class.key_type_rules).to be_empty
    end
  end

  # ─── Validation interface ─────────────────────────────────────────────

  describe 'validate_config' do
    describe 'direct-config validation' do
      let(:type_class) { OptionConfigs::TriggerTypes::ChangeUserRoles }

      it 'returns empty array for valid config' do
        config = { if: { all: 'condition' }, add_role_names: ['admin'] }
        warnings = type_class.validate_config(config)
        expect(warnings).to be_an(Array)
        expect(warnings).to be_empty
      end

      it 'warns about unrecognized keys' do
        config = { if: { all: 'condition' }, bad_key: 'something' }
        warnings = type_class.validate_config(config)
        expect(warnings).to be_present
        expect(warnings.any? { |w| w.include?('bad_key') }).to be(true)
      end
    end

    describe 'named-entry validation' do
      let(:type_class) { OptionConfigs::TriggerTypes::Notify }

      it 'returns empty array for valid named entry config' do
        config = { email_notification: { type: 'email', role: 'admin', subject: 'Test' } }
        warnings = type_class.validate_config(config)
        expect(warnings).to be_an(Array)
        expect(warnings).to be_empty
      end

      it 'warns about unrecognized keys inside a named entry' do
        config = { email_notification: { type: 'email', unknown_key: 'bad' } }
        warnings = type_class.validate_config(config)
        expect(warnings).to be_present
        expect(warnings.any? { |w| w.include?('unknown_key') }).to be(true)
      end

      it 'warns about key type violations' do
        config = { email_notification: { type: 123, role: 'admin' } }
        warnings = type_class.validate_config(config)
        expect(warnings).to be_present
        expect(warnings.any? { |w| w.include?('type') }).to be(true)
      end
    end

    describe 'delegate validation' do
      let(:type_class) { OptionConfigs::TriggerTypes::Transaction }

      it 'returns empty array regardless of config content' do
        config = { anything: 'goes', nested: { data: true } }
        warnings = type_class.validate_config(config)
        expect(warnings).to be_an(Array)
        expect(warnings).to be_empty
      end
    end

    describe 'key type checking for direct-config' do
      let(:type_class) { OptionConfigs::TriggerTypes::SetItemFlags }

      it 'returns no warnings when force_not_editable_save is boolean' do
        config = { force_not_editable_save: true, flags: ['flag1'] }
        warnings = type_class.validate_config(config)
        type_warnings = warnings.select { |w| w.include?('force_not_editable_save') }
        expect(type_warnings).to be_empty
      end

      it 'warns when force_not_editable_save is not boolean' do
        config = { force_not_editable_save: 'yes', flags: ['flag1'] }
        warnings = type_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('force_not_editable_save') }).to be(true)
      end
    end

    describe 'key type checking for named-entry' do
      let(:type_class) { OptionConfigs::TriggerTypes::RunBatchTrigger }

      it 'returns no warnings when limit is integer' do
        config = { my_batch: { resource_name: 'test', limit: 100 } }
        warnings = type_class.validate_config(config)
        type_warnings = warnings.select { |w| w.include?('limit') }
        expect(type_warnings).to be_empty
      end

      it 'warns when limit is not integer' do
        config = { my_batch: { resource_name: 'test', limit: '100' } }
        warnings = type_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('limit') }).to be(true)
      end
    end
  end
end
