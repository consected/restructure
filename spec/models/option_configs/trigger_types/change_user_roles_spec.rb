# frozen_string_literal: true

require 'rails_helper'

# Tests semantic validation of change_user_roles save trigger configurations,
# specifically nested app_type and for_user reference checks (issue #1374).
RSpec.describe OptionConfigs::TriggerTypes::ChangeUserRoles, type: :model do
  include ModelSupport

  before(:all) do
    create_admin
    @test_user, = create_user
    @active_app_type = Admin::AppType.create!(
      name: "chgroles-val-active-#{SecureRandom.hex(4)}",
      label: 'ChgRoles Active',
      current_admin: @admin
    )
    @disabled_app_type = Admin::AppType.create!(
      name: "chgroles-val-disabled-#{SecureRandom.hex(4)}",
      label: 'ChgRoles Disabled',
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
    context 'nested app_type reference validation (issue #1374)' do
      it 'produces no warning for a valid active app_type ID in add_role_names' do
        config = { add_role_names: [{ app_type: @active_app_type.id, role_name: 'test_role' }] }
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('app_type') }).to be true
      end

      it 'produces no warning for a valid active app_type name in add_role_names' do
        config = { add_role_names: [{ app_type: @active_app_type.name, role_name: 'test_role' }] }
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('app_type') }).to be true
      end

      it 'warns for a non-existent app_type ID in add_role_names' do
        config = { add_role_names: [{ app_type: -999, role_name: 'test_role' }] }
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('app_type') && w.include?('-999') }).to be true
      end

      it 'warns for a non-existent app_type name in add_role_names' do
        config = { add_role_names: [{ app_type: 'nonexistent_app_xyz', role_name: 'test_role' }] }
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('app_type') && w.include?('nonexistent_app_xyz') }).to be true
      end

      it 'warns for a disabled app_type in add_role_names' do
        config = { add_role_names: [{ app_type: @disabled_app_type.id, role_name: 'test_role' }] }
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('app_type') }).to be true
      end

      it 'warns for a non-existent app_type in remove_role_names' do
        config = { remove_role_names: [{ app_type: -888, role_name: 'test_role' }] }
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('app_type') && w.include?('-888') }).to be true
      end

      it 'skips validation for a {{substitution}} app_type' do
        config = { add_role_names: [{ app_type: '{{dynamic_app}}', role_name: 'test_role' }] }
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('app_type') }).to be true
      end

      it 'skips validation for a conditional hash app_type' do
        config = { add_role_names: [{ app_type: { this: { field: 'val' } }, role_name: 'test_role' }] }
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('app_type') }).to be true
      end
    end

    context 'nested for_user reference validation (issue #1374)' do
      it 'produces no warning for a valid active user ID in add_role_names' do
        config = { add_role_names: [{ for_user: @test_user.id, role_name: 'test_role' }] }
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('for_user') }).to be true
      end

      it 'produces no warning for a valid active user email in add_role_names' do
        config = { add_role_names: [{ for_user: @test_user.email, role_name: 'test_role' }] }
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('for_user') }).to be true
      end

      it 'warns for a non-existent user ID in add_role_names' do
        config = { add_role_names: [{ for_user: -999, role_name: 'test_role' }] }
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('for_user') && w.include?('-999') }).to be true
      end

      it 'warns for a non-existent user email in add_role_names' do
        config = { add_role_names: [{ for_user: 'no-one-xyz@example.com', role_name: 'test_role' }] }
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('for_user') && w.include?('no-one-xyz@example.com') }).to be true
      end

      it 'warns for a disabled user in add_role_names' do
        config = { add_role_names: [{ for_user: @disabled_user.id, role_name: 'test_role' }] }
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('for_user') && w.include?('disabled') }).to be true
      end

      it 'warns for an expired user in add_role_names' do
        config = { add_role_names: [{ for_user: @expired_user.id, role_name: 'test_role' }] }
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('for_user') && w.include?('expired') }).to be true
      end

      it 'warns for a non-existent user in remove_role_names' do
        config = { remove_role_names: [{ for_user: -888, role_name: 'test_role' }] }
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('for_user') && w.include?('-888') }).to be true
      end

      it 'skips validation for a {{substitution}} for_user' do
        config = { add_role_names: [{ for_user: '{{dynamic_user}}', role_name: 'test_role' }] }
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('for_user') }).to be true
      end

      it 'skips validation for a conditional hash for_user' do
        config = { add_role_names: [{ for_user: { this: { user_id: 'val' } }, role_name: 'test_role' }] }
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('for_user') }).to be true
      end
    end
  end
end
