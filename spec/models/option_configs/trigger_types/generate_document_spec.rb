# frozen_string_literal: true

require 'rails_helper'

# Tests semantic validation of generate_document save trigger configurations,
# specifically store_as_user and store_in_app_type reference checks (issue #1374).
RSpec.describe OptionConfigs::TriggerTypes::GenerateDocument, type: :model do
  include ModelSupport

  before(:all) do
    create_admin
    @test_user, = create_user
    @active_app_type = Admin::AppType.create!(
      name: "gendoc-val-active-#{SecureRandom.hex(4)}",
      label: 'GenDoc Active',
      current_admin: @admin
    )
    @disabled_app_type = Admin::AppType.create!(
      name: "gendoc-val-disabled-#{SecureRandom.hex(4)}",
      label: 'GenDoc Disabled',
      disabled: true,
      current_admin: @admin
    )
    @disabled_user, = create_user
    @disabled_user.current_admin = @admin
    @disabled_user.disabled = true
    @disabled_user.save!

    @expired_user, = create_user
    @expired_user.current_admin = @admin
    @expired_user.update_columns(expire_datetime: 1.day.ago)
  end

  describe '.validate_config' do
    let(:valid_entry_config) do
      {
        my_document: {
          filename: 'test.pdf',
          content_template_name: 'some_template'
        }
      }
    end

    context 'store_in_app_type reference validation (issue #1374)' do
      it 'warns for a non-existent app_type ID in a direct config' do
        config = valid_entry_config[:my_document].merge(store_in_app_type: -999)
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('store_in_app_type') && w.include?('-999') }).to be true
      end

      it 'produces no warning for a valid active app_type ID' do
        config = { my_doc: valid_entry_config[:my_document].merge(store_in_app_type: @active_app_type.id) }
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('app_type') }).to be true
      end

      it 'produces no warning for a valid active app_type name' do
        config = { my_doc: valid_entry_config[:my_document].merge(store_in_app_type: @active_app_type.name) }
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('app_type') }).to be true
      end

      it 'warns for a non-existent app_type ID' do
        config = { my_doc: valid_entry_config[:my_document].merge(store_in_app_type: -999) }
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('store_in_app_type') && w.include?('-999') }).to be true
      end

      it 'warns for a non-existent app_type name' do
        config = { my_doc: valid_entry_config[:my_document].merge(store_in_app_type: 'nonexistent_app_xyz') }
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('store_in_app_type') && w.include?('nonexistent_app_xyz') }).to be true
      end

      it 'warns for a disabled app_type' do
        config = { my_doc: valid_entry_config[:my_document].merge(store_in_app_type: @disabled_app_type.id) }
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('store_in_app_type') }).to be true
      end

      it 'skips validation for a {{substitution}}' do
        config = { my_doc: valid_entry_config[:my_document].merge(store_in_app_type: '{{dynamic_app}}') }
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('store_in_app_type') }).to be true
      end

      it 'skips validation for a conditional hash' do
        config = { my_doc: valid_entry_config[:my_document].merge(store_in_app_type: { this: { field: 'val' } }) }
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('store_in_app_type') }).to be true
      end
    end

    context 'store_as_user reference validation (issue #1374)' do
      it 'produces no warning for a valid active user ID' do
        config = { my_doc: valid_entry_config[:my_document].merge(store_as_user: @test_user.id) }
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('store_as_user') }).to be true
      end

      it 'produces no warning for a valid active user email' do
        config = { my_doc: valid_entry_config[:my_document].merge(store_as_user: @test_user.email) }
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('store_as_user') }).to be true
      end

      it 'warns for a non-existent user ID' do
        config = { my_doc: valid_entry_config[:my_document].merge(store_as_user: -999) }
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('store_as_user') && w.include?('-999') }).to be true
      end

      it 'warns for a non-existent user email' do
        config = { my_doc: valid_entry_config[:my_document].merge(store_as_user: 'no-one-xyz@example.com') }
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('store_as_user') && w.include?('no-one-xyz@example.com') }).to be true
      end

      it 'warns for a disabled user' do
        config = { my_doc: valid_entry_config[:my_document].merge(store_as_user: @disabled_user.id) }
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('store_as_user') && w.include?('disabled') }).to be true
      end

      it 'warns for an expired user' do
        config = { my_doc: valid_entry_config[:my_document].merge(store_as_user: @expired_user.id) }
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('store_as_user') && w.include?('expired') }).to be true
      end

      it 'skips validation for a {{substitution}}' do
        config = { my_doc: valid_entry_config[:my_document].merge(store_as_user: '{{dynamic_user}}') }
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('store_as_user') }).to be true
      end

      it 'skips validation for a conditional hash' do
        config = { my_doc: valid_entry_config[:my_document].merge(store_as_user: { this: { user_id: 'val' } }) }
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('store_as_user') }).to be true
      end
    end
  end
end
