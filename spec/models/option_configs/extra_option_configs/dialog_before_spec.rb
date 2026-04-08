# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for DialogBefore configuration class.
# Verifies NamedConfiguration pattern, template validation, and integration through
# ExtraOptions initialization (clean_dialog_before_def behavior).
RSpec.describe 'ExtraOptionConfigs::DialogBefore', type: :model do
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

  let(:klass) { OptionConfigs::ExtraOptionConfigs::DialogBefore }

  describe 'initialization' do
    before do
      Admin::MessageTemplate.create!(
        name: 'test_dialog',
        message_type: :dialog,
        template_type: :content,
        template: '<p>test</p>',
        current_admin: @admin
      )
    end

    it 'converts string to NamedConfiguration with name attribute' do
      instance = klass.new(field1: 'test_dialog')
      nc = instance[:field1]
      expect(nc).to be_a OptionConfigs::BaseNamedConfiguration
      expect(nc[:name]).to eq 'test_dialog'
    end

    it 'reports warning for missing template' do
      instance = klass.new(field1: 'nonexistent')
      expect(instance.config_warnings).not_to be_empty
    end
  end

  describe 'validate callbacks' do
    it 'produces ActiveModel errors when value is an invalid type' do
      instance = klass.new(test_field: 12_345)
      expect(instance.errors).to be_present,
                                 'Expected ActiveModel errors for invalid type, but none found'
    end

    it 'produces ActiveModel errors (warning level) when template does not exist' do
      instance = klass.new(test_field: { name: 'nonexistent_template_xyz_999' })
      expect(instance.errors.any? { |e| e.attribute == :dialog_before }).to be(true),
                                                                            'Expected ActiveModel error on :dialog_before for missing template, but none found'
    end

    it 'has no ActiveModel errors when given valid configuration' do
      Admin::MessageTemplate.create!(
        name: 'test_dialog_template_986',
        message_type: :dialog,
        template_type: :content,
        template: '<p>Test</p>',
        current_admin: @admin
      )
      instance = klass.new(test_field: { name: 'test_dialog_template_986' })
      expect(instance.errors).to be_empty,
                                 "Expected no ActiveModel errors for valid dialog_before, got: #{instance.errors.full_messages}"
    end
  end

  describe 'ExtraOptions integration' do
    it 'defaults dialog_before to a blank DialogBefore when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No dialogs
      YAML
      expect(eo.dialog_before).to be_blank
    end

    it 'converts a string value to a hash with name key' do
      Admin::MessageTemplate.create!(
        name: 'test_dialog_template',
        message_type: :dialog,
        template_type: :content,
        template: '<p>test</p>',
        current_admin: @admin
      )

      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          dialog_before:
            test1: test_dialog_template
      YAML

      db = eo.dialog_before[:test1]
      expect(db).to respond_to(:[])
      expect(db[:name]).to eq 'test_dialog_template'
    end

    it 'preserves a hash value with name key' do
      Admin::MessageTemplate.create!(
        name: 'test_dialog_hash',
        message_type: :dialog,
        template_type: :content,
        template: '<p>test</p>',
        current_admin: @admin
      )

      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          dialog_before:
            test1:
              name: test_dialog_hash
      YAML

      db = eo.dialog_before[:test1]
      expect(db[:name]).to eq 'test_dialog_hash'
    end

    it 'reports a warning when the named message template does not exist' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          dialog_before:
            test1: nonexistent_template
      YAML

      expect(eo.config_warnings).not_to be_empty
      warn_msg = eo.config_warnings.find { |w| w[:type].to_s.start_with?('dialog_before') }
      expect(warn_msg).to be_present
    end

    it 'reports an error when the value is not a String or Hash' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          dialog_before:
            test1:
              - invalid_array_item
      YAML

      expect(eo.config_errors).not_to be_empty
      err = eo.config_errors.find { |e| e[:type].to_s.start_with?('dialog_before') }
      expect(err).to be_present
    end

    it 'symbolizes dialog_before keys' do
      Admin::MessageTemplate.create!(
        name: 'dialog_sym_test',
        message_type: :dialog,
        template_type: :content,
        template: '<p>test</p>',
        current_admin: @admin
      )

      eo = config_for(<<~YAML)
        default:
          dialog_before:
            test1: dialog_sym_test
      YAML

      expect(eo.dialog_before.keys.first).to be_a Symbol
    end
  end
end
