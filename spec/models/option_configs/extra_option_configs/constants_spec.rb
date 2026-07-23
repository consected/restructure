# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for Constants configuration class (top-level _constants options).
# Verifies Hash-like access and integration through ExtraOptions.parse_config.
# Constants provide user-defined key-value pairs for runtime
# {{constants.name}} template substitutions.
RSpec.describe 'ExtraOptionConfigs::Constants', type: :model do
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

  let(:klass) { OptionConfigs::ExtraOptionConfigs::Constants }

  describe 'initialization' do
    it 'stores arbitrary key-value pairs' do
      instance = klass.new(app_name: 'My App', version: '1.0')
      expect(instance[:app_name]).to eq 'My App'
      expect(instance[:version]).to eq '1.0'
    end

    it 'is blank when empty' do
      instance = klass.new({})
      expect(instance).to be_blank
    end

    it 'supports dup for safe copying' do
      instance = klass.new(key1: 'val1')
      copy = instance.dup
      expect(copy[:key1]).to eq 'val1'
    end

    it 'to_h returns a plain Hash for substitution compatibility' do
      instance = klass.new(replace_me: 'super special', program_name: 'LC2Test')
      h = instance.to_h
      expect(h).to be_a(Hash)
      expect(h[:replace_me]).to eq 'super special'
      expect(h[:program_name]).to eq 'LC2Test'
      expect(h.key?(:replace_me)).to be true
    end
  end

  describe 'parse_config integration' do
    it 'wraps _constants in a Constants instance' do
      @dm.update!(options: <<~YAML)
        _constants:
          study_name: Test Study
          version: '2.0'
        default:
          label: Test
      YAML
      @dm.reload
      @dm.option_configs force: true

      expect(@dm.options_constants).to be_a(klass)
      expect(@dm.options_constants[:study_name]).to eq 'Test Study'
      expect(@dm.options_constants[:version]).to eq '2.0'
    end

    it 'returns blank Constants when no _constants defined' do
      @dm.update!(options: <<~YAML)
        default:
          label: No constants
      YAML
      @dm.reload
      @dm.option_configs force: true

      expect(@dm.options_constants).to be_a(klass)
      expect(@dm.options_constants).to be_blank
    end
  end
end
