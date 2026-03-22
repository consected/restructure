# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Describe how valid_if works in dynamic model options
# Tests correspond to examples in app/models/admin/defs/valid_if_options_defs.yaml
RSpec.describe 'Dynamic Model valid_if Options', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include OptionsSupport
  include ValidIfSupport

  let(:resource_name) { :dynamic_model__test_valid_if_recs }
  let(:resource_class) { DynamicModel::TestValidIfRec }
  let(:table_name) { 'test_valid_if_recs' }
  let(:schema_name) { 'ml_app' }

  before(:example) do
    create_admin
    create_user
    create_master

    # Create additional users for email validation tests (create_user returns [user, password])
    @other_user, = create_user('other-user')
    @another_user, = create_user('another-user')
  end

  after(:each) do
    cleanup_test_dm
  end

  # Example 1: Basic Field Validation
  # Reference: valid_if_options_defs.yaml - Example 1
  # Tests simple field validation with invalid_error_message in this: block
  describe 'basic valid_if functionality' do
    it 'validates when condition is met' do
      options_yaml = <<~YAML
        _configurations:
          use_current_version: true
        _default:
          fields:
            - email
            - status
          valid_if:
            on_save:
              all:
                this:
                  status: 'active'
                  invalid_error_message: 'Status must be active'
      YAML

      create_test_dm(options_yaml)

      rec = make_test_record(email: 'test@example.com', status: 'active')
      expect(rec.save).to be_truthy
      expect(rec.errors.full_messages).to be_empty
    end

    it 'fails validation when condition is not met' do
      options_yaml = <<~YAML
        _configurations:
          use_current_version: true
        _default:
          fields:
            - email
            - status
          valid_if:
            on_save:
              all:
                this:
                  status: 'active'
                  invalid_error_message: 'Status must be active'
      YAML

      create_test_dm(options_yaml)

      rec = make_test_record(email: 'test@example.com', status: 'inactive')
      expect(rec.save).to be_falsey
      expect(rec.errors.full_messages.any? { |m| m.include?('invalid_error_message: Status must be active') }).to be_truthy
    end
  end

  # Example 2: Multiple Field Conditions
  # Reference: valid_if_options_defs.yaml - Example 2
  # Tests validation requiring multiple field values simultaneously
  describe 'multiple field conditions' do
    it 'validates when both conditions are met' do
      options_yaml = <<~YAML
        _configurations:
          use_current_version: true
        _default:
          fields:
            - email
            - status
            - item_type
          valid_if:
            on_save:
              all:
                this:
                  status: 'active'
                  item_type: 'primary'
                  invalid_error_message: 'Record must have status=active and item_type=primary'
      YAML

      create_test_dm(options_yaml, field_list: 'email status item_type')

      rec = make_test_record(email: 'test@example.com', status: 'active', item_type: 'primary')
      expect(rec.save).to be_truthy
      expect(rec.errors.full_messages).to be_empty
    end

    it 'fails when one condition is not met' do
      options_yaml = <<~YAML
        _configurations:
          use_current_version: true
        _default:
          fields:
            - email
            - status
            - item_type
          valid_if:
            on_save:
              all:
                this:
                  status: 'active'
                  item_type: 'primary'
                  invalid_error_message: 'Record must have status=active and item_type=primary'
      YAML

      create_test_dm(options_yaml, field_list: 'email status item_type')

      rec = make_test_record(email: 'test@example.com', status: 'active', item_type: 'secondary')
      expect(rec.save).to be_falsey
      expect(rec.errors.full_messages.any? { |m| m.include?('Record must have status=active and item_type=primary') }).to be_truthy
    end
  end

  # Example 3: Cross-Table Email Validation
  # Reference: valid_if_options_defs.yaml - Example 3
  # Tests cross-table validation with named condition wrapper and no_masters: {}
  describe 'cross-table validation' do
    it 'validates email exists as a user in the system using no_masters and users table' do
      options_yaml = <<~YAML
        _configurations:
          use_current_version: true
        _default:
          fields:
            - email
            - status
          valid_if:
            on_save:
              all:
                all_user_exists:
                  invalid_error_message: 'This email address does not exist as a user of the system'
                  no_masters: {}
                  users:
                    email:
                      this: email
      YAML

      create_test_dm(options_yaml)

      # Valid record - email exists as a user
      rec1 = make_test_record(email: @other_user.email, status: 'active')
      expect(rec1.save).to be_truthy
      expect(rec1.errors.full_messages).to be_empty

      # Valid record - another existing user email
      rec2 = make_test_record(email: @another_user.email, status: 'active')
      expect(rec2.save).to be_truthy
      expect(rec2.errors.full_messages).to be_empty

      # Invalid record - email does not exist as a user
      rec3 = make_test_record(email: 'nonexistent@example.com', status: 'active')
      expect(rec3.save).to be_falsey
      expect(rec3.errors.full_messages.any? { |m| m.include?('This email address does not exist as a user of the system') }).to be_truthy
    end
  end
end
