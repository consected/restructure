# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for FieldOptions configuration class.
# Verifies alt_options preprocessing and integration through
# ExtraOptions initialization (clean_field_options_def behavior).
RSpec.describe 'ExtraOptionConfigs::FieldOptions', type: :model do
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

  let(:klass) { OptionConfigs::ExtraOptionConfigs::FieldOptions }

  describe 'initialization' do
    it 'converts alt_options Array to Hash' do
      instance = klass.new(
        field1: { edit_as: { alt_options: %w[ChoiceA ChoiceB] } }
      )
      ao = instance[:field1][:edit_as][:alt_options]
      expect(ao).to be_a Hash
      expect(ao[:ChoiceA]).to eq 'choicea'
    end
  end

  describe 'ExtraOptions integration' do
    it 'defaults field_options to a blank FieldOptions instance when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No field options
      YAML
      expect(eo.field_options).to be_blank
    end

    it 'preserves field_options and symbolizes keys' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          field_options:
            test1:
              no_downcase: true
      YAML
      expect(eo.field_options[:test1]).to eq(no_downcase: true)
    end

    it 'converts edit_as.alt_options from Array to Hash' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          field_options:
            test1:
              edit_as:
                field_type: select
                alt_options:
                  - Choice A
                  - Choice B
      YAML

      ao = eo.field_options[:test1][:edit_as][:alt_options]
      expect(ao).to be_a Hash
      expect(ao[:'Choice A']).to eq 'choice a'
      expect(ao[:'Choice B']).to eq 'choice b'
    end

    it 'preserves edit_as.alt_options when already a Hash' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          field_options:
            test1:
              edit_as:
                field_type: select
                alt_options:
                  'Option 1': opt1
                  'Option 2': opt2
      YAML

      ao = eo.field_options[:test1][:edit_as][:alt_options]
      expect(ao).to be_a Hash
      expect(ao[:'Option 1']).to eq 'opt1'
    end
  end
end
