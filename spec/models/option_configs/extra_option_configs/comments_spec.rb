# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for Comments configuration class (top-level _comments options).
# Verifies Hash-like access, recognized key warnings, and integration
# through ExtraOptions.parse_config including handle_table_comments enrichment.
RSpec.describe 'ExtraOptionConfigs::Comments', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include ExtraOptionConfigsSupport

  before(:all) do
    set_up_extra_options_configs
  end

  let(:klass) { OptionConfigs::ExtraOptionConfigs::Comments }

  describe 'initialization' do
    it 'stores table and fields comments' do
      instance = klass.new(table: 'My table', fields: { col1: 'Column one' })
      expect(instance[:table]).to eq 'My table'
      expect(instance[:fields]).to eq(col1: 'Column one')
    end

    it 'supports []= for mutation' do
      instance = klass.new(table: 'X')
      instance[:original_fields] = { col1: 'backup' }
      expect(instance[:original_fields]).to eq(col1: 'backup')
    end

    it 'is blank when empty' do
      instance = klass.new({})
      expect(instance).to be_blank
    end

    it 'warns about unrecognized keys' do
      instance = klass.new(table: 'X', bogus: 'bad')
      expect(instance.config_warnings).not_to be_empty
    end

    it 'does not warn about recognized keys' do
      instance = klass.new(table: 'X', fields: {}, original_fields: {})
      expect(instance.config_warnings).to be_empty
    end
  end

  describe 'parse_config integration' do
    it 'wraps _comments in a Comments instance' do
      @dm.update!(options: <<~YAML)
        _comments:
          table: Test table
        default:
          label: Test
      YAML
      @dm.reload
      @dm.option_configs force: true

      expect(@dm.table_comments).to be_a(klass)
      expect(@dm.table_comments[:table]).to eq 'Test table'
    end

    it 'enriches fields from caption_before and labels' do
      @dm.update!(options: <<~YAML)
        _comments:
          table: Test table
        default:
          label: Test
          caption_before:
            test1: A test caption
      YAML
      @dm.reload
      @dm.option_configs force: true

      expect(@dm.table_comments[:fields][:test1]).to eq 'A test caption'
    end

    it 'returns a Comments instance when no _comments defined' do
      @dm.update!(options: <<~YAML)
        default:
          label: No comments
      YAML
      @dm.reload
      @dm.option_configs force: true

      expect(@dm.table_comments).to be_a(klass)
    end
  end
end
