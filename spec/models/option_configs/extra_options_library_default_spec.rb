# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for GitHub issue #521:
# "Adding `_default:` to a config library breaks configurations if other config
# library `_definitions...:` appear below it"
#
# Verifies that:
# - Config libraries containing `_default:` don't corrupt YAML when combined with
#   other libraries containing `_definitions...:` blocks
# - The admin panel shows parse errors gracefully instead of raising exceptions

RSpec.describe OptionConfigs::ExtraOptions, '.include_libraries with _default and _definitions', type: :model do
  include ModelSupport
  include DynamicModelSupport

  before :all do
    change_setting('AllowDynamicMigrations', true)
    create_admin
    create_user
    @rand_suffix = rand(1_000_000_000)

    unless Admin::MigrationGenerator.table_exists? 'test_lib_default_opts'
      TableGenerators.dynamic_models_table('test_lib_default_opts', :create_do, 'field_1', 'field_2')
    end
  end

  after :all do
    change_setting('AllowDynamicMigrations', false)
  end

  # Creates a pair of config libraries: one with _definitions: anchors,
  # one with both _definitions: anchors and a _default: block.
  # Returns [definitions_only_name, default_with_definitions_name]
  def create_library_pair(category)
    defs_name = "defs_lib_#{@rand_suffix}"
    Admin::ConfigLibrary.create!(
      current_admin: @admin,
      name: defs_name,
      category:,
      format: 'yaml',
      options: <<~YAML
        _definitions:
          never_show: &never_show
            never: true
      YAML
    )

    field_opts_name = "field_opts_lib_#{@rand_suffix}"
    Admin::ConfigLibrary.create!(
      current_admin: @admin,
      name: field_opts_name,
      category:,
      format: 'yaml',
      options: <<~YAML
        _definitions:
          field_never: &field_never
            never: true

        _default:
          show_if:
            a_field:
              this:
                status: *field_never
      YAML
    )

    [defs_name, field_opts_name]
  end

  def generate_dm_with_options(options_yaml)
    DynamicModel.active.where(table_name: 'test_lib_default_opts').reload.each { |d| d.disable!(@admin) }
    if DynamicModel.const_defined?(:TestLibDefaultOpt, false)
      DynamicModel.send(:remove_const, :TestLibDefaultOpt)
    end

    DynamicModel.create!(
      current_admin: @admin,
      name: 'test lib default opts',
      table_name: 'test_lib_default_opts',
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test,
      field_list: 'field_1 field_2',
      options: options_yaml
    )
  end

  def parse_options_for(options_yaml)
    dm = generate_dm_with_options(options_yaml)
    dm.class.options_provider.parse_config(dm)
  end

  describe 'library with _default: included above library with _definitions:' do
    before :each do
      @cat = "deflib_cat_#{@rand_suffix}"
      @lib_defs_name, @lib_field_opts_name = create_library_pair(@cat)
    end

    it 'parses correctly when _default: library appears above _definitions: library' do
      configs = parse_options_for(<<~YAML)
        # @library #{@cat} #{@lib_field_opts_name}
        # @library #{@cat} #{@lib_defs_name}

        my_option_type:
          labels:
            field_1: My Field
      YAML

      expect(configs.map(&:name)).to include(:my_option_type)
    end

    it 'parses correctly when _definitions: library appears above _default: library' do
      configs = parse_options_for(<<~YAML)
        # @library #{@cat} #{@lib_defs_name}
        # @library #{@cat} #{@lib_field_opts_name}

        another_option_type:
          labels:
            field_1: Another Field
      YAML

      expect(configs.map(&:name)).to include(:another_option_type)
    end

    it 'does not treat _definitions_xxx: blocks as option types when _default: precedes them' do
      # Reproduces issue #521: anchor definitions indented under _definitions:
      # appear after library substitution. Without the fix, _default: from a
      # library absorbs subsequent indented content as its children.
      configs = parse_options_for(<<~YAML)
        _definitions:
          fs_enabled: &fs_enabled
            always: true

        # @library #{@cat} #{@lib_field_opts_name}
        # @library #{@cat} #{@lib_defs_name}

          update_reference_ref_status: &update_ref_status
            force_not_editable_save: true

        real_option_type:
          labels:
            field_1: Real Field
          save_trigger:
            on_save:
              first:
                top_referring_record:
                  update: return_result
      YAML

      config_names = configs.map(&:name)
      definitions_as_types = config_names.select { |n| n.to_s.start_with?('_definitions') }
      expect(definitions_as_types).to be_empty,
        "Expected no _definitions entries as option types, but found: #{definitions_as_types}"
      expect(config_names).to include(:real_option_type)
    end
  end

  describe 'graceful error handling when library collision causes parse failure' do
    it 'returns error notices instead of raising when option_configs fails to parse' do
      cat = "badlib_cat_#{@rand_suffix}"
      defs_name, default_name = create_library_pair(cat)

      dm = generate_dm_with_options(<<~YAML)
        # @library #{cat} #{default_name}
        # @library #{cat} #{defs_name}

        some_bad_anchor_usage: &some_bad_ref
          force_not_editable_save: true

        valid_option:
          labels:
            field_1: Valid
      YAML

      result = OptionConfigs::ExtraOptions.all_option_configs_notices(dm)
      expect(result).to be_present
      error_types = result.map { |r| r[:type] }
      expect(error_types).to include(:parse_error).or include(:error)
    end
  end
end
