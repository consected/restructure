# frozen_string_literal: true

require 'rails_helper'

# Tests for validation of unexpected underscore-prefixed keys in option configs.
# Issue #1163: A typo like _definition_ (instead of _definitions_) would be silently treated as
# a new option type rather than reported as a config error. Any key starting with underscore
# that remains after all special keys (_definitions_, _comments, _db_columns, _data_dictionary,
# _constants, _configurations, _default, _merge_default, _merge_override, _override) are
# processed should raise FphsOptionsParseError.
RSpec.describe OptionConfigs::ExtraOptions, type: :model do
  include ModelSupport

  describe 'unexpected underscore key detection' do
    before(:each) do
      create_admin
    end

    it 'raises a parse error when config contains a typo underscore key like _definition_ instead of _definitions_' do
      invalid_options_text = <<~YAML
        _definition_data_request_form_field_options:
          some_field:
            label: Something
        default:
          fields:
            - field_1
            - field_2
      YAML

      dm = DynamicModel.new(
        name: 'test_underscore_key_typo',
        table_name: 'test_underscore_key_typo',
        schema_name: 'dynamic_test',
        options: invalid_options_text,
        current_admin: @admin
      )

      expect do
        dm.option_configs(raise_bad_configs: [FphsOptionsParseError])
      end.to raise_error(FphsOptionsParseError) do |error|
        expect(error.message).to match(/_definition_data_request_form_field_options/)
        expect(error.message).to match(/invalid.*underscore|unexpected.*underscore/i)
      end
    end

    it 'raises a parse error listing all unexpected underscore keys' do
      invalid_options_text = <<~YAML
        _typo_key_one:
          label: Something
        _another_bad_key:
          label: Other
        default:
          fields:
            - field_1
      YAML

      dm = DynamicModel.new(
        name: 'test_multiple_bad_underscore_keys',
        table_name: 'test_multiple_bad_underscore_keys',
        schema_name: 'dynamic_test',
        options: invalid_options_text,
        current_admin: @admin
      )

      expect do
        dm.option_configs(raise_bad_configs: [FphsOptionsParseError])
      end.to raise_error(FphsOptionsParseError) do |error|
        expect(error.message).to match(/_typo_key_one/)
        expect(error.message).to match(/_another_bad_key/)
      end
    end

    it 'does not raise an error for valid _definitions_ keys' do
      valid_options_text = <<~YAML
        _definitions_my_defs:
          my_val: &my_val
            - some_value
        default:
          fields:
            - field_1
            - field_2
      YAML

      dm = DynamicModel.new(
        name: 'test_valid_definitions_key',
        table_name: 'test_valid_definitions_key',
        schema_name: 'dynamic_test',
        options: valid_options_text,
        current_admin: @admin
      )

      expect do
        dm.option_configs(raise_bad_configs: [FphsOptionsParseError])
      end.not_to raise_error
    end

    it 'does not raise an error for valid _default key' do
      valid_options_text = <<~YAML
        _default:
          label: Default Label
        my_type:
          fields:
            - field_1
      YAML

      dm = DynamicModel.new(
        name: 'test_valid_default_key',
        table_name: 'test_valid_default_key',
        schema_name: 'dynamic_test',
        options: valid_options_text,
        current_admin: @admin
      )

      expect do
        dm.option_configs(raise_bad_configs: [FphsOptionsParseError])
      end.not_to raise_error
    end

    it 'does not raise an error for valid _merge_default key' do
      valid_options_text = <<~YAML
        _merge_default:
          label: Merge Default Label
        my_type:
          fields:
            - field_1
      YAML

      dm = DynamicModel.new(
        name: 'test_valid_merge_default_key',
        table_name: 'test_valid_merge_default_key',
        schema_name: 'dynamic_test',
        options: valid_options_text,
        current_admin: @admin
      )

      expect do
        dm.option_configs(raise_bad_configs: [FphsOptionsParseError])
      end.not_to raise_error
    end

    it 'does not raise an error for valid _override key' do
      valid_options_text = <<~YAML
        _override:
          label: Override Label
        my_type:
          fields:
            - field_1
      YAML

      dm = DynamicModel.new(
        name: 'test_valid_override_key',
        table_name: 'test_valid_override_key',
        schema_name: 'dynamic_test',
        options: valid_options_text,
        current_admin: @admin
      )

      expect do
        dm.option_configs(raise_bad_configs: [FphsOptionsParseError])
      end.not_to raise_error
    end

    it 'does not raise an error for valid _merge_override key' do
      valid_options_text = <<~YAML
        _merge_override:
          label: Merge Override Label
        my_type:
          fields:
            - field_1
      YAML

      dm = DynamicModel.new(
        name: 'test_valid_merge_override_key',
        table_name: 'test_valid_merge_override_key',
        schema_name: 'dynamic_test',
        options: valid_options_text,
        current_admin: @admin
      )

      expect do
        dm.option_configs(raise_bad_configs: [FphsOptionsParseError])
      end.not_to raise_error
    end

    it 'does not raise an error for valid _comments key' do
      valid_options_text = <<~YAML
        _comments:
          table: My table comment
          fields:
            field_1: A comment
        default:
          fields:
            - field_1
      YAML

      dm = DynamicModel.new(
        name: 'test_valid_comments_key',
        table_name: 'test_valid_comments_key',
        schema_name: 'dynamic_test',
        options: valid_options_text,
        current_admin: @admin
      )

      expect do
        dm.option_configs(raise_bad_configs: [FphsOptionsParseError])
      end.not_to raise_error
    end

    it 'suggests checking for _definitions_ typo in error message when key starts with _definition_' do
      invalid_options_text = <<~YAML
        _definition_something:
          my_field: value
        default:
          fields:
            - field_1
      YAML

      dm = DynamicModel.new(
        name: 'test_definitions_typo_suggestion',
        table_name: 'test_definitions_typo_suggestion',
        schema_name: 'dynamic_test',
        options: invalid_options_text,
        current_admin: @admin
      )

      expect do
        dm.option_configs(raise_bad_configs: [FphsOptionsParseError])
      end.to raise_error(FphsOptionsParseError) do |error|
        expect(error.message).to match(/_definitions_/i)
      end
    end
  end
end
