# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for the PatternValidation concern shared across field-keyed BaseConfiguration subclasses.
# Verifies:
#   1. extra_keys DSL accepts symbols and regexes for non-field key validation
#   2. value_pattern DSL declares valid value shapes with type, allowed_keys, required_keys, key_types
#   3. key_type DSL declares type constraints on top-level hash keys
#   4. validate_field_key_names reports warnings for unrecognized keys
#   5. validate_value_patterns reports errors for type mismatches, warnings for unknown hash keys,
#      errors for missing required keys, errors for key_types violations
#   6. validate_key_types reports warnings for unrecognized keys and errors for type mismatches
#   7. Default prepare_config injects _valid_fields from parent context
#   8. All field-keyed config classes declare appropriate patterns
RSpec.describe 'PatternValidation concern', type: :model do
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

  describe 'extra_keys DSL' do
    it 'CaptionBefore declares all_fields, submit, and reference_ pattern' do
      keys = OptionConfigs::ExtraOptionConfigs::CaptionBefore._extra_keys
      expect(keys).to include(:all_fields)
      expect(keys).to include(:submit)
      expect(keys.any? { |k| k.is_a?(Regexp) }).to be(true)
    end

    it 'DialogBefore declares all_fields and submit' do
      keys = OptionConfigs::ExtraOptionConfigs::DialogBefore._extra_keys
      expect(keys).to include(:all_fields)
      expect(keys).to include(:submit)
    end

    it 'Labels declares no extra_keys' do
      keys = OptionConfigs::ExtraOptionConfigs::Labels._extra_keys
      expect(keys).to be_empty
    end

    it 'ShowIf declares no extra_keys' do
      keys = OptionConfigs::ExtraOptionConfigs::ShowIf._extra_keys
      expect(keys).to be_empty
    end

    it 'FieldOptions declares no extra_keys' do
      keys = OptionConfigs::ExtraOptionConfigs::FieldOptions._extra_keys
      expect(keys).to be_empty
    end

    it 'DbConfigs declares no extra_keys' do
      keys = OptionConfigs::ExtraOptionConfigs::DbConfigs._extra_keys
      expect(keys).to be_empty
    end
  end

  describe 'value_pattern DSL' do
    it 'CaptionBefore declares String and Hash patterns' do
      patterns = OptionConfigs::ExtraOptionConfigs::CaptionBefore._value_patterns
      expect(patterns.keys).to include(:simple_caption, :caption_hash)
      expect(patterns[:simple_caption][:match]).to eq String
      expect(patterns[:caption_hash][:match]).to eq Hash
      expect(patterns[:caption_hash][:allowed_keys]).to be_present
    end

    it 'DialogBefore declares String and Hash patterns with required name' do
      patterns = OptionConfigs::ExtraOptionConfigs::DialogBefore._value_patterns
      expect(patterns.keys).to include(:simple_template, :dialog_hash)
      expect(patterns[:dialog_hash][:required_keys]).to include(:name)
    end

    it 'Labels declares a String-only pattern' do
      patterns = OptionConfigs::ExtraOptionConfigs::Labels._value_patterns
      expect(patterns.size).to eq 1
      expect(patterns.values.first[:match]).to eq String
    end

    it 'ShowIf declares a Hash-only pattern' do
      patterns = OptionConfigs::ExtraOptionConfigs::ShowIf._value_patterns
      expect(patterns.size).to eq 1
      expect(patterns.values.first[:match]).to eq Hash
    end

    it 'FieldOptions declares a Hash pattern with allowed_keys' do
      patterns = OptionConfigs::ExtraOptionConfigs::FieldOptions._value_patterns
      expect(patterns.size).to eq 1
      expect(patterns.values.first[:match]).to eq Hash
      expect(patterns.values.first[:allowed_keys]).to be_present
    end

    it 'DbConfigs declares a Hash pattern with allowed_keys' do
      patterns = OptionConfigs::ExtraOptionConfigs::DbConfigs._value_patterns
      expect(patterns.size).to eq 1
      expect(patterns.values.first[:match]).to eq Hash
      expect(patterns.values.first[:allowed_keys]).to be_present
    end

    it 'PresetFields declares no value patterns (any value accepted)' do
      patterns = OptionConfigs::ExtraOptionConfigs::PresetFields._value_patterns
      expect(patterns).to be_empty
    end
  end

  describe 'field key validation via ExtraOptions integration' do
    shared_examples 'field key validation' do |config_attr, valid_yaml, invalid_yaml|
      it 'accepts valid field names without warnings' do
        eo = config_for(valid_yaml)
        config = eo.send(config_attr)
        field_warnings = config.config_warnings.select { |w| w[:message].match?(/not a valid field/) }
        expect(field_warnings).to be_empty
      end

      it 'warns about invalid field names' do
        eo = config_for(invalid_yaml)
        config = eo.send(config_attr)
        field_warnings = config.config_warnings.select { |w| w[:message].match?(/not a valid field/) }
        expect(field_warnings).to be_present,
          "Expected field name warning on #{config_attr}, got: #{config.config_warnings}"
      end
    end

    context 'labels' do
      include_examples 'field key validation', :labels,
                       <<~YAML, <<~YAML
                         default:
                           fields:
                             - test1
                           labels:
                             test1: My Label
                       YAML
                         default:
                           fields:
                             - test1
                           labels:
                             nonexistent_field: Bad Label
                       YAML
    end

    context 'show_if' do
      include_examples 'field key validation', :show_if,
                       <<~YAML, <<~YAML
                         default:
                           fields:
                             - test1
                             - test2
                           show_if:
                             test1:
                               test2: value
                       YAML
                         default:
                           fields:
                             - test1
                           show_if:
                             nonexistent_field:
                               test1: value
                       YAML
    end

    context 'field_options' do
      include_examples 'field key validation', :field_options,
                       <<~YAML, <<~YAML
                         default:
                           fields:
                             - test1
                           field_options:
                             test1:
                               no_downcase: true
                       YAML
                         default:
                           fields:
                             - test1
                           field_options:
                             nonexistent_field:
                               no_downcase: true
                       YAML
    end

    context 'db_configs' do
      include_examples 'field key validation', :db_configs,
                       <<~YAML, <<~YAML
                         default:
                           fields:
                             - test1
                           db_configs:
                             test1:
                               type: string
                       YAML
                         default:
                           fields:
                             - test1
                           db_configs:
                             nonexistent_field:
                               type: string
                       YAML
    end

    context 'preset_fields' do
      include_examples 'field key validation', :preset_fields,
                       <<~YAML, <<~YAML
                         default:
                           fields:
                             - test1
                           preset_fields:
                             test1: preset_value
                       YAML
                         default:
                           fields:
                             - test1
                           preset_fields:
                             nonexistent_field: preset_value
                       YAML
    end
  end

  describe 'value pattern validation' do
    context 'Labels rejects non-string values' do
      it 'errors on Hash value' do
        instance = OptionConfigs::ExtraOptionConfigs::Labels.new(test1: { nested: 'bad' })
        expect(instance.config_errors).to be_present
      end

      it 'errors on Integer value' do
        instance = OptionConfigs::ExtraOptionConfigs::Labels.new(test1: 123)
        expect(instance.config_errors).to be_present
      end

      it 'accepts String value' do
        instance = OptionConfigs::ExtraOptionConfigs::Labels.new(test1: 'Valid label')
        expect(instance.config_errors).to be_empty
      end
    end

    context 'ShowIf rejects non-hash values' do
      it 'errors on String value' do
        instance = OptionConfigs::ExtraOptionConfigs::ShowIf.new(test1: 'bad')
        expect(instance.config_errors).to be_present
      end

      it 'accepts Hash value' do
        instance = OptionConfigs::ExtraOptionConfigs::ShowIf.new(test1: { test2: 'value' })
        expect(instance.config_errors).to be_empty
      end
    end

    context 'FieldOptions rejects non-hash values' do
      it 'errors on String value' do
        instance = OptionConfigs::ExtraOptionConfigs::FieldOptions.new(test1: 'bad')
        expect(instance.config_errors).to be_present
      end

      it 'accepts Hash value' do
        instance = OptionConfigs::ExtraOptionConfigs::FieldOptions.new(test1: { no_downcase: true })
        expect(instance.config_errors).to be_empty
      end
    end

    context 'DbConfigs rejects non-hash values' do
      it 'errors on String value' do
        instance = OptionConfigs::ExtraOptionConfigs::DbConfigs.new(test1: 'bad')
        expect(instance.config_errors).to be_present
      end

      it 'accepts Hash value' do
        instance = OptionConfigs::ExtraOptionConfigs::DbConfigs.new(test1: { type: 'string' })
        expect(instance.config_errors).to be_empty
      end
    end

    context 'DialogBefore required keys' do
      it 'errors when name is missing from hash value' do
        instance = OptionConfigs::ExtraOptionConfigs::DialogBefore.new(test1: { label: 'no name' })
        expect(instance.config_errors).to be_present
        error_messages = instance.config_errors.map { |e| e[:message] }
        expect(error_messages.any? { |m| m.include?('name') }).to be(true)
      end

      it 'accepts hash with required name key' do
        Admin::MessageTemplate.create!(
          name: 'pv_test_template',
          message_type: :dialog,
          template_type: :content,
          template: '<p>Test</p>',
          current_admin: @admin
        )
        instance = OptionConfigs::ExtraOptionConfigs::DialogBefore.new(test1: { name: 'pv_test_template' })
        errors_without_template_warnings = instance.config_errors.reject { |e| e[:message].include?('template') }
        expect(errors_without_template_warnings).to be_empty
      end
    end

    context 'PresetFields accepts any value type (no value patterns)' do
      it 'accepts String values' do
        instance = OptionConfigs::ExtraOptionConfigs::PresetFields.new(test1: 'preset')
        expect(instance.config_errors).to be_empty
      end

      it 'accepts Hash values' do
        instance = OptionConfigs::ExtraOptionConfigs::PresetFields.new(test1: { key: 'val' })
        expect(instance.config_errors).to be_empty
      end

      it 'accepts Array values' do
        instance = OptionConfigs::ExtraOptionConfigs::PresetFields.new(test1: %w[a b])
        expect(instance.config_errors).to be_empty
      end
    end
  end

  describe 'match_value_pattern introspection' do
    let(:caption_klass) { OptionConfigs::ExtraOptionConfigs::CaptionBefore }

    it 'returns the matched pattern for a String value' do
      instance = caption_klass.new(test1: 'caption text')
      pattern = instance.match_value_pattern('a string')
      expect(pattern).to be_present
      expect(pattern[:description]).to include('string')
    end

    it 'returns the matched pattern for a Hash value' do
      instance = caption_klass.new(test1: { caption: 'text' })
      pattern = instance.match_value_pattern({ caption: 'text' })
      expect(pattern).to be_present
      expect(pattern[:description]).to include('hash').or include('Hash')
    end

    it 'returns nil for an unmatched value type' do
      instance = caption_klass.new(test1: 'text')
      pattern = instance.match_value_pattern(12_345)
      expect(pattern).to be_nil
    end
  end

  describe 'key_type DSL' do
    it 'Configurations declares boolean, string, string_or_array and hash key types' do
      rules = OptionConfigs::ExtraOptionConfigs::Configurations._key_type_rules
      expect(rules[:prevent_migrations][:type]).to eq :boolean
      expect(rules[:secondary_key][:type]).to eq :string
      expect(rules[:uniqueness_fields][:type]).to eq :string_or_array
      expect(rules[:batch_trigger][:type]).to eq :hash
      expect(rules[:batch_trigger][:allowed_keys]).to include(:frequency, :limit)
    end

    it 'derives allowed keys from all key_type declarations' do
      allowed = OptionConfigs::ExtraOptionConfigs::Configurations.key_type_allowed_keys
      expect(allowed).to include(:prevent_migrations, :secondary_key, :uniqueness_fields, :batch_trigger)
    end

    it 'ViewOptions declares boolean, string, string_or_array and hash key types' do
      rules = OptionConfigs::ExtraOptionConfigs::ViewOptions._key_type_rules
      expect(rules[:show_embedded_at_top][:type]).to eq :boolean
      expect(rules[:header_caption][:type]).to eq :string
      expect(rules[:data_attribute][:type]).to eq :string_or_array
      expect(rules[:sort_references][:type]).to eq :hash
      expect(rules[:sort_references][:allowed_keys]).to include(:attribute, :direction)
    end

    it 'reports a warning for unrecognized keys' do
      klass = OptionConfigs::ExtraOptionConfigs::Configurations
      instance = klass.new(bogus_key: 'unknown')
      expect(instance.config_warnings).not_to be_empty
      expect(instance.config_warnings.first[:message]).to include("unrecognized key 'bogus_key'")
    end

    it 'reports an error for boolean type mismatch' do
      klass = OptionConfigs::ExtraOptionConfigs::Configurations
      instance = klass.new(prevent_migrations: 'nope')
      expect(instance.errors[:prevent_migrations]).not_to be_empty
    end

    it 'reports an error for string type mismatch' do
      klass = OptionConfigs::ExtraOptionConfigs::Configurations
      instance = klass.new(secondary_key: 123)
      expect(instance.errors[:secondary_key]).not_to be_empty
    end

    it 'reports an error for string_or_array type mismatch' do
      klass = OptionConfigs::ExtraOptionConfigs::Configurations
      instance = klass.new(uniqueness_fields: 42)
      expect(instance.errors[:uniqueness_fields]).not_to be_empty
    end

    it 'reports an error for hash type mismatch' do
      klass = OptionConfigs::ExtraOptionConfigs::Configurations
      instance = klass.new(batch_trigger: 'not a hash')
      expect(instance.errors[:batch_trigger]).not_to be_empty
    end

    it 'warns about unrecognized sub-keys in hash-typed keys' do
      klass = OptionConfigs::ExtraOptionConfigs::Configurations
      instance = klass.new(batch_trigger: { frequency: '1 hour', bogus: 'bad' })
      expect(instance.config_warnings).not_to be_empty
    end
  end

  describe 'value_pattern key_types' do
    it 'DbConfigs declares key_types for column config values' do
      patterns = OptionConfigs::ExtraOptionConfigs::DbConfigs._value_patterns
      kt = patterns[:db_config_hash][:key_types]
      expect(kt[:type]).to eq :string
      expect(kt[:array]).to eq :boolean
      expect(kt[:index]).to eq :boolean
      expect(kt[:encrypted]).to eq :boolean
    end

    it 'DbColumns declares key_types for column config values' do
      patterns = OptionConfigs::ExtraOptionConfigs::DbColumns._value_patterns
      kt = patterns[:column_config][:key_types]
      expect(kt[:type]).to eq :string
      expect(kt[:array]).to eq :boolean
    end

    it 'reports an error for key_types violation in value_pattern' do
      klass = OptionConfigs::ExtraOptionConfigs::DbColumns
      instance = klass.new(name: { type: 123, array: 'yes' })
      expect(instance.errors).not_to be_empty
    end

    it 'raises ArgumentError when key_types keys are not in allowed_keys' do
      expect do
        Class.new(OptionConfigs::ExtraOptionConfigs::BaseConfiguration) do
          value_pattern :bad_pattern,
                        description: 'Bad pattern',
                        match: Hash,
                        allowed_keys: %i[foo bar],
                        key_types: { foo: :string, missing: :boolean }
        end
      end.to raise_error(ArgumentError, /missing.*not in allowed_keys/)
    end

    it 'does not raise when key_types keys are subset of allowed_keys' do
      expect do
        Class.new(OptionConfigs::ExtraOptionConfigs::BaseConfiguration) do
          value_pattern :good_pattern,
                        description: 'Good pattern',
                        match: Hash,
                        allowed_keys: %i[foo bar baz],
                        key_types: { foo: :string, bar: :boolean }
        end
      end.not_to raise_error
    end
  end
end
