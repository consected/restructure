# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for CaptionBefore configuration class.
# Verifies the BaseConfiguration/NamedConfiguration pattern, hash-like interface,
# JSON serialization, unrecognized attribute warnings, and integration through
# ExtraOptions initialization (clean_caption_before_def behavior).
RSpec.describe 'ExtraOptionConfigs::CaptionBefore', type: :model do
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

  let(:klass) { OptionConfigs::ExtraOptionConfigs::CaptionBefore }

  describe 'class structure' do
    it 'inherits from BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::BaseConfiguration)
    end

    it 'defines a NamedConfiguration inner class' do
      expect(klass.const_defined?(:NamedConfiguration)).to be true
    end

    it 'NamedConfiguration inherits from BaseNamedConfiguration' do
      expect(klass::NamedConfiguration.ancestors).to include(OptionConfigs::BaseNamedConfiguration)
    end

    it 'NamedConfiguration declares caption attributes via configure_attributes' do
      expected = %i[caption edit_caption show_caption new_caption keep_label]
      expected.each do |attr|
        expect(klass::NamedConfiguration.option_types[:simple]).to include(attr)
      end
    end
  end

  context 'initialized with a raw hash' do
    let(:raw_config) { { test1: 'Simple text', test2: { caption: 'Cap', edit_caption: 'Edit' } } }
    let(:instance) { klass.new(raw_config) }

    it 'creates named configurations for each field' do
      expect(instance.configurations).to have_key(:test1)
      expect(instance.configurations).to have_key(:test2)
    end

    it 'stores NamedConfiguration objects in configurations' do
      expect(instance.configurations[:test1]).to be_a klass::NamedConfiguration
      expect(instance.configurations[:test2]).to be_a klass::NamedConfiguration
    end

    it 'preprocesses string values into all caption modes' do
      nc = instance.configurations[:test1]
      expect(nc.caption).to be_present
      expect(nc.edit_caption).to eq nc.caption
      expect(nc.show_caption).to eq nc.caption
      expect(nc.new_caption).to eq nc.caption
    end

    it 'preserves hash values with individual mode settings' do
      nc = instance.configurations[:test2]
      expect(nc.caption).to include('Cap')
      expect(nc.edit_caption).to include('Edit')
    end

    it 'preserves keep_label for field captions that should retain the label element' do
      keep_label_instance = klass.new(test3: { caption: 'Cap', keep_label: true })

      expect(keep_label_instance[:test3][:keep_label]).to be_present
    end

    it 'defaults new_caption to edit_caption when not specified' do
      nc = instance.configurations[:test2]
      expect(nc.new_caption).to eq nc.edit_caption
    end
  end

  context 'hash-like interface' do
    let(:raw_config) { { test1: 'Caption text' } }
    let(:instance) { klass.new(raw_config) }

    it '[] returns a NamedConfiguration for a given field' do
      expect(instance[:test1]).to be_a klass::NamedConfiguration
    end

    it '[] returns nil for missing fields' do
      expect(instance[:nonexistent]).to be_nil
    end

    it 'NamedConfiguration supports [] for attribute access' do
      nc = instance[:test1]
      expect(nc[:caption]).to eq nc.caption
      expect(nc[:edit_caption]).to eq nc.edit_caption
    end

    it 'supports keys method' do
      expect(instance.keys).to eq [:test1]
    end

    it 'supports each iteration' do
      yielded = []
      instance.each { |k, v| yielded << [k, v.class] }
      expect(yielded).to eq [[:test1, klass::NamedConfiguration]]
    end

    it 'supports blank? for empty config' do
      empty = klass.new({})
      expect(empty).to be_blank
    end

    it 'supports blank? for populated config' do
      expect(instance).not_to be_blank
    end

    it 'supports merge! with a plain hash' do
      instance.merge!(test2: { caption: 'New cap' })
      expect(instance[:test2]).to be_a klass::NamedConfiguration
      expect(instance[:test2].caption).to include('New cap')
    end

    it 'supports []= assignment' do
      instance[:test3] = { caption: 'Assigned' }
      expect(instance[:test3]).to be_a klass::NamedConfiguration
      expect(instance[:test3].caption).to include('Assigned')
    end

    it 'symbolize_keys returns a plain Hash for backward compat' do
      result = instance.symbolize_keys
      expect(result).to be_a Hash
      expect(result[:test1]).to be_a Hash
      expect(result[:test1]).to have_key(:caption)
    end
  end

  context 'JSON serialization' do
    let(:raw_config) { { test1: 'Cap text', test2: { caption: 'C', edit_caption: 'E' } } }
    let(:instance) { klass.new(raw_config) }

    it 'as_json returns a plain nested hash' do
      json = instance.as_json
      expect(json).to be_a Hash
      expect(json['test1']).to be_a Hash
      expect(json['test1']).to have_key('caption')
    end

    it 'to_json produces valid JSON matching the expected format' do
      json_str = instance.to_json
      parsed = JSON.parse(json_str)
      expect(parsed).to have_key('test1')
      expect(parsed['test1']).to have_key('caption')
    end

    it 'empty config serializes to empty JSON object' do
      empty = klass.new({})
      expect(JSON.parse(empty.to_json)).to eq({})
    end
  end

  context 'unrecognized NamedConfiguration attributes' do
    it 'reports a config warning when a field has an unrecognized attribute' do
      raw = { test1: { caption: 'Valid', bogus_attr: 'Invalid' } }
      instance = klass.new(raw)
      expect(instance.config_warnings).to be_present,
                                          'Expected config_warnings for unrecognized attribute bogus_attr'
      warning_messages = instance.config_warnings.map { |w| w[:message] }
      expect(warning_messages.any? { |m| m.include?('bogus_attr') }).to be(true),
                                                                        "Expected warning mentioning 'bogus_attr', got: #{warning_messages}"
    end

    it 'does not report warnings for valid attributes only' do
      raw = { test1: { caption: 'Cap', edit_caption: 'Edit', show_caption: 'Show', new_caption: 'New', keep_label: true } }
      instance = klass.new(raw)
      expect(instance.config_warnings).to be_empty,
                                          "Expected no config_warnings for valid attributes, got: #{instance.config_warnings}"
    end

    it 'does not report warnings for string values (auto-expanded)' do
      raw = { test1: 'Simple text' }
      instance = klass.new(raw)
      expect(instance.config_warnings).to be_empty,
                                          "Expected no config_warnings for string value, got: #{instance.config_warnings}"
    end

    it 'reports multiple unrecognized attributes in a single field' do
      raw = { test1: { caption: 'Valid', bad1: 'x', bad2: 'y' } }
      instance = klass.new(raw)
      warning_messages = instance.config_warnings.map { |w| w[:message] }
      expect(warning_messages.any? { |m| m.include?('bad1') }).to be(true)
      expect(warning_messages.any? { |m| m.include?('bad2') }).to be(true)
    end

    it 'reports unrecognized attributes across multiple fields' do
      raw = { field1: { caption: 'OK', nope1: 'x' }, field2: { bogus2: 'y' } }
      instance = klass.new(raw)
      warning_messages = instance.config_warnings.map { |w| w[:message] }
      expect(warning_messages.any? { |m| m.include?('nope1') }).to be(true)
      expect(warning_messages.any? { |m| m.include?('bogus2') }).to be(true)
    end
  end

  describe 'ExtraOptions integration' do
    it 'defaults caption_before to a blank CaptionBefore when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No captions
      YAML
      expect(eo.caption_before).to be_blank
    end

    it 'converts a plain string caption to a hash with all caption modes' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          caption_before:
            test1: Simple caption text
      YAML

      cb = eo.caption_before[:test1]
      expect(cb).to respond_to(:[])
      expect(cb[:caption]).to be_present
      expect(cb[:edit_caption]).to be_present
      expect(cb[:show_caption]).to be_present
      expect(cb[:new_caption]).to be_present
      expect(cb[:caption]).to eq cb[:edit_caption]
      expect(cb[:caption]).to eq cb[:show_caption]
      expect(cb[:caption]).to eq cb[:new_caption]
    end

    it 'converts text to HTML via Formatter::Substitution.text_to_html' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          caption_before:
            test1: "Line one\\nLine two"
      YAML

      cb = eo.caption_before[:test1]
      expect(cb[:caption]).to be_a String
      expect(cb[:caption]).not_to be_empty
    end

    it 'preserves hash-style caption_before with individual mode values' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          caption_before:
            test1:
              caption: Show and edit caption
              edit_caption: Edit only caption
              show_caption: Show only caption
      YAML

      cb = eo.caption_before[:test1]
      expect(cb[:caption]).to include('Show and edit caption')
      expect(cb[:edit_caption]).to include('Edit only caption')
      expect(cb[:show_caption]).to include('Show only caption')
    end

    it 'defaults new_caption to edit_caption when not explicitly set' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          caption_before:
            test1:
              edit_caption: Edit caption value
      YAML

      cb = eo.caption_before[:test1]
      expect(cb[:new_caption]).to eq cb[:edit_caption]
    end

    it 'retains keep_label so edit forms can preserve labels after captions' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          caption_before:
            test1:
              caption: Edit caption value
              keep_label: true
      YAML

      cb = eo.caption_before[:test1]
      expect(cb[:keep_label]).to be_present
    end

    it 'symbolizes caption_before keys' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          caption_before:
            test1: A caption
      YAML

      expect(eo.caption_before.keys.first).to be_a Symbol
    end
  end

  describe 'validation' do
    context 'value type validation' do
      it 'rejects non-string non-hash values with an error' do
        instance = klass.new(test1: 123)
        expect(instance.config_errors).to be_present
        error_messages = instance.config_errors.map { |e| e[:message] }
        expect(error_messages.any? { |m| m.include?('test1') }).to be(true)
      end

      it 'rejects array values with an error' do
        instance = klass.new(test1: %w[a b c])
        expect(instance.config_errors).to be_present
        error_messages = instance.config_errors.map { |e| e[:message] }
        expect(error_messages.any? { |m| m.include?('test1') }).to be(true)
      end

      it 'rejects boolean values with an error' do
        instance = klass.new(test1: true)
        expect(instance.config_errors).to be_present
      end

      it 'accepts string values without errors' do
        instance = klass.new(test1: 'Valid caption')
        expect(instance.config_errors).to be_empty
      end

      it 'accepts hash values without errors' do
        instance = klass.new(test1: { caption: 'Valid' })
        expect(instance.config_errors).to be_empty
      end
    end

    context 'hash value key validation' do
      it 'warns on unrecognized hash keys' do
        instance = klass.new(test1: { caption: 'Valid', bogus_key: 'bad' })
        expect(instance.config_warnings).to be_present
        warning_messages = instance.config_warnings.map { |w| w[:message] }
        expect(warning_messages.any? { |m| m.include?('bogus_key') }).to be(true)
      end

      it 'accepts all recognized hash keys without warnings' do
        instance = klass.new(test1: { caption: 'C', edit_caption: 'E', show_caption: 'S', new_caption: 'N', keep_label: true })
        expect(instance.config_warnings).to be_empty
      end
    end

    context 'contextual field name validation via ExtraOptions integration' do
      it 'accepts valid field names without warnings' do
        eo = config_for(<<~YAML)
          default:
            fields:
              - test1
              - test2
            caption_before:
              test1: Valid caption
              test2: Also valid
        YAML

        expect(eo.caption_before.config_warnings).to be_empty
      end

      it 'warns when a caption_before key is not a valid field name or pseudo-key' do
        eo = config_for(<<~YAML)
          default:
            fields:
              - test1
            caption_before:
              nonexistent_field: Bad caption
        YAML

        warnings = eo.caption_before.config_warnings
        warning_messages = warnings.map { |w| w[:message] }
        expect(warning_messages.any? { |m| m.include?('nonexistent_field') }).to be(true),
                                                                                 "Expected warning about nonexistent_field, got: #{warning_messages}"
      end

      it 'accepts the all_fields pseudo-key without warnings' do
        eo = config_for(<<~YAML)
          default:
            fields:
              - test1
            caption_before:
              all_fields: Caption for all
        YAML

        field_warnings = eo.caption_before.config_warnings.select { |w| w[:message].include?('all_fields') }
        expect(field_warnings).to be_empty
      end

      it 'accepts the submit pseudo-key without warnings' do
        eo = config_for(<<~YAML)
          default:
            fields:
              - test1
            caption_before:
              submit: Caption before submit
        YAML

        field_warnings = eo.caption_before.config_warnings.select { |w| w[:message].include?('submit') }
        expect(field_warnings).to be_empty
      end

      it 'accepts reference_ prefixed keys without field name warnings' do
        eo = config_for(<<~YAML)
          default:
            fields:
              - test1
            caption_before:
              reference_some_ref: Caption above reference
        YAML

        field_warnings = eo.caption_before.config_warnings.select { |w| w[:message].include?('reference_some_ref') }
        expect(field_warnings).to be_empty
      end

      it 'warns about multiple invalid field names' do
        eo = config_for(<<~YAML)
          default:
            fields:
              - test1
            caption_before:
              bad_field_1: Caption 1
              bad_field_2: Caption 2
        YAML

        warnings = eo.caption_before.config_warnings
        warning_messages = warnings.map { |w| w[:message] }
        expect(warning_messages.any? { |m| m.include?('bad_field_1') }).to be(true)
        expect(warning_messages.any? { |m| m.include?('bad_field_2') }).to be(true)
      end

      it 'allows a mix of valid fields and pseudo-keys without field warnings' do
        eo = config_for(<<~YAML)
          default:
            fields:
              - test1
              - test2
            caption_before:
              test1: Field caption
              all_fields: All fields caption
              submit: Submit caption
              reference_my_ref: Reference caption
        YAML

        field_warnings = eo.caption_before.config_warnings.select { |w| w[:message].match?(/not a valid field/) }
        expect(field_warnings).to be_empty
      end
    end
  end
end
