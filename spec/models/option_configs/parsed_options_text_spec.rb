# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for the parsed_options_text class method on option provider classes.
# This method parses YAML (resolving anchors/aliases), applies _default,
# _merge_default, _merge_override, and _override processing via
# handle_defaults_merges_overrides, then dumps the final config to clean YAML.
#
# These tests verify that YAML anchors are resolved, defaults/merges/overrides
# are applied, nil is returned for blank options, the output is valid
# re-parseable YAML, and malformed YAML raises FphsOptionsParseError.
#
# Related to GitHub issue #992: "Parsed Config" tab should resolve YAML anchors.

RSpec.describe OptionConfigs::ExtraOptions, '.parsed_options_text', type: :model do
  include ModelSupport
  include DynamicModelSupport

  before :all do
    change_setting('AllowDynamicMigrations', true)
  end

  after :all do
    change_setting('AllowDynamicMigrations', false)
  end

  before :each do
    create_admin
    create_user
  end

  describe 'resolving YAML anchors' do
    it 'resolves anchors and aliases in the options text' do
      yaml_with_anchors = <<~YAML
        _definitions:
          valid_options: &valid_options
            - option_a
            - option_b
            - option_c

        default:
          labels:
            field_1: Test Field
          view_options:
            data_attribute: field_1
          valid_if:
            on_save:
              all:
                this:
                  field_1: *valid_options
      YAML

      dm = generate_dm_with_options(yaml_with_anchors)
      provider = dm.class.options_provider

      result = provider.parsed_options_text(dm)

      expect(result).to be_present

      # The resolved output should not contain YAML anchors (&) or aliases (*)
      expect(result).not_to match(/&valid_options/)
      expect(result).not_to match(/\*valid_options/)

      # The resolved values should be expanded inline
      parsed = YAML.safe_load(result, permitted_classes: [], permitted_symbols: [], aliases: true)
      valid_if_values = parsed.dig('default', 'valid_if', 'on_save', 'all', 'this', 'field_1')
      expect(valid_if_values).to eq %w[option_a option_b option_c]
    end

    it 'resolves standard definition anchors from prepended files' do
      # Standard definitions include anchors like &never, &is_blank, etc.
      # These should be resolved when referenced via aliases (*never, *is_blank)
      yaml_with_standard_refs = <<~YAML
        default:
          labels:
            field_1: Test Field
          showable_if:
            field_1:
              this:
                status: *is_blank
      YAML

      dm = generate_dm_with_options(yaml_with_standard_refs)
      provider = dm.class.options_provider

      result = provider.parsed_options_text(dm)

      expect(result).to be_present
      # Standard anchors like &is_blank and *is_blank should be resolved
      expect(result).not_to match(/\*is_blank/)

      # The resolved value should be the actual definition content
      parsed = YAML.safe_load(result, permitted_classes: [], permitted_symbols: [], aliases: true)
      showable_status = parsed.dig('default', 'showable_if', 'field_1', 'this', 'status')
      expect(showable_status).to be_present
    end
  end

  describe 'when options text is blank' do
    it 'returns nil when config object has no options text' do
      dm = generate_dm_with_options(nil)
      provider = dm.class.options_provider

      result = provider.parsed_options_text(dm)

      expect(result).to be_nil
    end
  end

  describe 'output validity' do
    it 'produces valid YAML that can be re-parsed' do
      yaml_with_anchors = <<~YAML
        _definitions:
          shared_label: &shared_label My Shared Label
          shared_fields: &shared_fields
            - field_1
            - field_2

        default:
          labels:
            field_1: *shared_label
          fields: *shared_fields
          view_options:
            data_attribute: field_1
      YAML

      dm = generate_dm_with_options(yaml_with_anchors)
      provider = dm.class.options_provider

      result = provider.parsed_options_text(dm)

      expect(result).to be_present

      # Re-parsing should succeed without error
      reparsed = YAML.safe_load(result, permitted_classes: [], permitted_symbols: [], aliases: true)
      expect(reparsed).to be_a(Hash)

      # Verify specific resolved values
      expect(reparsed.dig('default', 'labels', 'field_1')).to eq 'My Shared Label'
      expect(reparsed.dig('default', 'fields')).to eq %w[field_1 field_2]
    end
  end

  describe 'defaults and merges processing' do
    it 'applies _default entries to all option types' do
      yaml_with_defaults = <<~YAML
        _default:
          labels:
            field_1: Default Label
          view_options:
            data_attribute: field_1

        default:
          labels:
            field_2: Custom Label

        secondary:
          labels:
            field_1: Secondary Label
      YAML

      dm = generate_dm_with_options(yaml_with_defaults)
      provider = dm.class.options_provider

      result = provider.parsed_options_text(dm)

      expect(result).to be_present
      parsed = YAML.safe_load(result, permitted_classes: [], permitted_symbols: [], aliases: true)

      # _default uses shallow merge, so default's labels replaces _default's labels entirely
      expect(parsed.dig('default', 'labels', 'field_2')).to eq 'Custom Label'
      # But view_options from _default is preserved since default doesn't define it
      expect(parsed.dig('default', 'view_options', 'data_attribute')).to eq 'field_1'

      # secondary also gets _default's view_options
      expect(parsed.dig('secondary', 'view_options', 'data_attribute')).to eq 'field_1'
      expect(parsed.dig('secondary', 'labels', 'field_1')).to eq 'Secondary Label'
    end
  end

  describe 'error handling' do
    it 'raises FphsOptionsParseError for malformed YAML' do
      malformed_yaml = <<~YAML
        default:
          labels:
            field_1: Test
          bad_indent:
        - broken
      YAML

      dm = generate_dm_with_options(malformed_yaml)
      provider = dm.class.options_provider

      expect { provider.parsed_options_text(dm) }.to raise_error(FphsOptionsParseError)
    end

    it 'handles _configurations without error' do
      yaml_with_configurations = <<~YAML
        _configurations:
          use_current_version: true

        default:
          labels:
            field_1: Test Field
          view_options:
            data_attribute: field_1
      YAML

      dm = generate_dm_with_options(yaml_with_configurations)
      provider = dm.class.options_provider

      result = provider.parsed_options_text(dm)

      expect(result).to be_present
      parsed = YAML.safe_load(result, permitted_classes: [], permitted_symbols: [], aliases: true)
      # _configurations should be stripped from output (consumed internally)
      expect(parsed).not_to have_key('_configurations')
      expect(parsed.dig('default', 'labels', 'field_1')).to eq 'Test Field'
    end
  end

  private

  # Create a DynamicModel definition with the given options YAML for testing
  def generate_dm_with_options(options_yaml)
    DynamicModel.active.where(table_name: 'test_parsed_opts').reload.each { |d| d.disable!(@admin) }
    DynamicModel.send(:remove_const, :TestParsedOpt) if DynamicModel.const_defined?(:TestParsedOpt, false)

    DynamicModel.create!(
      current_admin: @admin,
      name: 'test parsed opts',
      table_name: 'test_parsed_opts',
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test,
      field_list: 'field_1 field_2',
      options: options_yaml
    )
  end
end
