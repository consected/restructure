# frozen_string_literal: true

require 'rails_helper'

# Tests for GitHub Issue #1178:
# "_constants and _configurations merging"
#
# When config libraries contain `_constants:` or `_configurations:` blocks,
# they should be merged from all referenced libraries (similar to `_definitions`).
# Currently `_constants` and `_configurations` are NOT in LibraryKeyRenamePatterns,
# so when multiple blocks share the same key name in the injected YAML text, the
# YAML parser silently drops all but the last one.
#
# Expected behaviour after fix:
# - `_constants:` in a library gets renamed to `_constants__category_name:` on injection
# - `_constants:` in a definition (and in every library) are all merged into options_constants
# - `_configurations:` in a library gets renamed to `_configurations__category_name:` on injection
# - Multiple `_configurations:` blocks (from libraries and definition) are all merged together
#
# Strategy:
# 1. Create Admin::ConfigLibrary records with _constants / _configurations blocks
# 2. Create DynamicModel.new (no DB table required) that references those libraries
# 3. Call dm.option_configs to trigger parse_config / include_libraries
# 4. Assert that options_constants / configurations contain values from all sources

RSpec.describe 'Config library _constants and _configurations merging - Issue #1178', type: :model do
  include ModelSupport
  include OptionsSupport

  before :example do
    create_admin
  end

  # Helper: create a config library with arbitrary YAML options
  def create_config_library(category:, name:, options_yaml:)
    Admin::ConfigLibrary.create!(
      current_admin: @admin,
      name: name,
      category: category,
      format: 'yaml',
      options: options_yaml
    )
  end

  # Helper: build (not save) a DynamicModel whose options text references the given library
  def build_dm_with_options(options_yaml)
    DynamicModel.new(
      name: 'test_merge_dm',
      table_name: 'test_merge_dm_recs',
      schema_name: 'dynamic_test',
      options: options_yaml,
      current_admin: @admin
    )
  end

  describe '_constants merging' do
    it 'merges _constants from a library with _constants defined directly in the definition' do
      category = "test_const_cat_#{rand(1_000_000_000)}"
      name     = "test_const_lib_#{rand(1_000_000_000)}"

      create_config_library(
        category: category,
        name: name,
        options_yaml: <<~YAML
          _constants:
            lib_var: library_value
        YAML
      )

      dm = build_dm_with_options(<<~YAML)
        # @library #{category} #{name}
        _constants:
          direct_var: direct_value
        default:
          fields:
            - id
      YAML

      dm.option_configs

      constants = dm.options_constants

      expect(constants).to be_a(OptionConfigs::ExtraOptionConfigs::Constants)
      expect(constants[:lib_var]).to eq('library_value'),
                                     "Expected lib_var from library to be present in options_constants, got: #{constants.inspect}"
      expect(constants[:direct_var]).to eq('direct_value'),
                                        "Expected direct_var from definition to be present in options_constants, got: #{constants.inspect}"
    end

    it 'merges _constants from two different libraries into a single options_constants hash' do
      category1 = "test_const_cat1_#{rand(1_000_000_000)}"
      name1     = "test_const_lib1_#{rand(1_000_000_000)}"
      category2 = "test_const_cat2_#{rand(1_000_000_000)}"
      name2     = "test_const_lib2_#{rand(1_000_000_000)}"

      create_config_library(
        category: category1,
        name: name1,
        options_yaml: <<~YAML
          _constants:
            var_from_lib1: value_from_lib1
        YAML
      )

      create_config_library(
        category: category2,
        name: name2,
        options_yaml: <<~YAML
          _constants:
            var_from_lib2: value_from_lib2
        YAML
      )

      dm = build_dm_with_options(<<~YAML)
        # @library #{category1} #{name1}
        # @library #{category2} #{name2}
        default:
          fields:
            - id
      YAML

      dm.option_configs

      constants = dm.options_constants

      expect(constants).to be_a(OptionConfigs::ExtraOptionConfigs::Constants)
      expect(constants[:var_from_lib1]).to eq('value_from_lib1'),
                                           "Expected var_from_lib1 to be in options_constants, got: #{constants.inspect}"
      expect(constants[:var_from_lib2]).to eq('value_from_lib2'),
                                           "Expected var_from_lib2 to be in options_constants, got: #{constants.inspect}"
    end
  end

  describe '_configurations merging' do
    it 'merges _configurations from a library with _configurations defined directly in the definition' do
      category = "test_cfg_cat_#{rand(1_000_000_000)}"
      name     = "test_cfg_lib_#{rand(1_000_000_000)}"

      create_config_library(
        category: category,
        name: name,
        options_yaml: <<~YAML
          _configurations:
            option_type_attr_name: lib_type_field
        YAML
      )

      dm = build_dm_with_options(<<~YAML)
        # @library #{category} #{name}
        _configurations:
          secondary_key: direct_secondary
        default:
          fields:
            - id
      YAML

      dm.option_configs

      configurations = dm.configurations

      expect(configurations).to be_a(OptionConfigs::ExtraOptionConfigs::Configurations)
      expect(configurations[:option_type_attr_name]).to eq('lib_type_field'),
                                                        "Expected option_type_attr_name from library to be in configurations, got: #{configurations.inspect}"
      expect(configurations[:secondary_key]).to eq('direct_secondary'),
                                                "Expected secondary_key from definition to be in configurations, got: #{configurations.inspect}"
    end
  end

  describe '_constants and _configurations from separate libraries do not conflict' do
    it 'each library contributes its own constants and configurations without overwriting others' do
      cat_a = "test_multi_cat_a_#{rand(1_000_000_000)}"
      lib_a = "test_multi_lib_a_#{rand(1_000_000_000)}"
      cat_b = "test_multi_cat_b_#{rand(1_000_000_000)}"
      lib_b = "test_multi_lib_b_#{rand(1_000_000_000)}"

      create_config_library(
        category: cat_a,
        name: lib_a,
        options_yaml: <<~YAML
          _constants:
            const_a: value_a
          _configurations:
            option_type_attr_name: type_from_a
        YAML
      )

      create_config_library(
        category: cat_b,
        name: lib_b,
        options_yaml: <<~YAML
          _constants:
            const_b: value_b
          _configurations:
            secondary_key: secondary_from_b
        YAML
      )

      dm = build_dm_with_options(<<~YAML)
        # @library #{cat_a} #{lib_a}
        # @library #{cat_b} #{lib_b}
        default:
          fields:
            - id
      YAML

      dm.option_configs

      constants      = dm.options_constants
      configurations = dm.configurations

      expect(constants[:const_a]).to eq('value_a'),
                                     "Expected const_a from lib_a in options_constants, got: #{constants.inspect}"
      expect(constants[:const_b]).to eq('value_b'),
                                     "Expected const_b from lib_b in options_constants, got: #{constants.inspect}"

      expect(configurations[:option_type_attr_name]).to eq('type_from_a'),
                                                        "Expected option_type_attr_name from lib_a in configurations, got: #{configurations.inspect}"
      expect(configurations[:secondary_key]).to eq('secondary_from_b'),
                                                "Expected secondary_key from lib_b in configurations, got: #{configurations.inspect}"
    end
  end
  describe 'overriding and precedence' do
    it 'allows definition to override library constants and configurations with the same inner key' do
      category = "test_over_cat_#{rand(1_000_000_000)}"
      name     = "test_over_lib_#{rand(1_000_000_000)}"

      create_config_library(
        category: category,
        name: name,
        options_yaml: <<~YAML
          _constants:
            shared_var: value_from_library
          _configurations:
            shared_cfg: cfg_from_library
        YAML
      )

      dm = build_dm_with_options(<<~YAML)
        # @library #{category} #{name}
        _constants:
          shared_var: value_from_definition
        _configurations:
          shared_cfg: cfg_from_definition
        default:
          fields:
            - id
      YAML

      dm.option_configs

      expect(dm.options_constants[:shared_var]).to eq('value_from_definition')
      expect(dm.configurations[:shared_cfg]).to eq('cfg_from_definition')
    end
  end

  describe 'parsed_options_text edge case' do
    it 'strips library-prefixed _constants and _configurations from parsed_options_text to prevent leakage' do
      category = "test_leak_cat_#{rand(1_000_000_000)}"
      name     = "test_leak_lib_#{rand(1_000_000_000)}"

      create_config_library(
        category: category,
        name: name,
        options_yaml: <<~YAML
          _constants:
            lib_var: lib_val
          _configurations:
            lib_cfg: lib_cfg_val
        YAML
      )

      dm = build_dm_with_options(<<~YAML)
        # @library #{category} #{name}
        _constants:
          direct_var: direct_val
        default:
          fields:
            - id
      YAML

      # Trigger options parsing and the parsed_options_text generation
      dm.option_configs
      
      parsed_text = OptionConfigs::ExtraOptions.parsed_options_text(dm)
      
      expect(parsed_text).not_to include('_constants')
      expect(parsed_text).not_to include('_configurations')
      expect(parsed_text).not_to include(category) # ensuring the prefixed variant is also gone
    end
  end
end
