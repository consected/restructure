# frozen_string_literal: true

require 'rails_helper'

# Tests semantic validation of notify save trigger configurations,
# including role/user existence checks (issue #1374).
RSpec.describe OptionConfigs::TriggerTypes::Notify, type: :model do
  include ModelSupport

  before(:all) do
    create_admin
    @layout_email = Admin::MessageTemplate.create!(
      name: 'test_notify_email_layout',
      message_type: :email,
      template_type: :layout,
      template: '<html><body>{{main_content}}</body></html>',
      current_admin: @admin
    )
    @content_email = Admin::MessageTemplate.create!(
      name: 'test_notify_email_content',
      message_type: :email,
      template_type: :content,
      template: '<p>Hello {{name}}</p>',
      current_admin: @admin
    )
    @layout_sms = Admin::MessageTemplate.create!(
      name: 'test_notify_sms_layout',
      message_type: :sms,
      template_type: :layout,
      template: 'SMS: {{main_content}}',
      current_admin: @admin
    )

    @test_user, = create_user
    @test_user2, = create_user
    @existing_role_name = "notify_val_test_role_#{SecureRandom.hex(4)}"
    Admin::UserRole.create!(
      app_type: @test_user.app_type,
      user: @test_user,
      role_name: @existing_role_name,
      current_admin: @admin
    )
    @other_app_type = Admin::AppType.create!(name: 'notify-validation-other', label: 'Notify Validation Other', current_admin: @admin)
    @other_role_name = "notify_val_other_role_#{SecureRandom.hex(4)}"
    Admin::UserRole.create!(
      app_type: @other_app_type,
      user: @test_user,
      role_name: @other_role_name,
      current_admin: @admin
    )
  end

  describe '.validate_config' do
    it 'produces no warnings for a valid email notify config with content_template' do
      config = {
        type: 'email',
        role: 'admin',
        subject: 'Notification Subject',
        layout_template: 'test_notify_email_layout',
        content_template: 'test_notify_email_content'
      }

      warnings = described_class.validate_config(config)
      expect(warnings).to be_empty
    end

    it 'produces no warnings for a valid email notify config with content_template_text' do
      config = {
        type: 'email',
        role: 'admin',
        subject: 'Notification Subject',
        layout_template: 'test_notify_email_layout',
        content_template_text: 'Direct message text'
      }

      warnings = described_class.validate_config(config)
      expect(warnings).to be_empty
    end

    it 'produces no warnings for a valid sms notify config' do
      config = {
        type: 'sms',
        phones: '+16175550100',
        layout_template: 'test_notify_sms_layout',
        content_template_text: 'SMS text',
        importance: 'Transactional'
      }

      warnings = described_class.validate_config(config)
      expect(warnings).to be_empty
    end

    it 'skips static checks for template substitutions and conditional hashes' do
      config = {
        type: '{{calculated_type}}',
        layout_template: '{{dynamic_layout}}',
        content_template: '{{dynamic_content}}',
        importance: '{{select_importance}}',
        subject: { this: { title: 'return_value' } }
      }

      warnings = described_class.validate_config(config)
      expect(warnings).to be_empty
    end

    it 'warns when type is missing' do
      config = {
        role: 'admin',
        layout_template: 'test_notify_email_layout',
        content_template_text: 'Hello'
      }

      warnings = described_class.validate_config(config)
      expect(warnings).to include('type is required')
    end

    it 'warns when type is invalid' do
      config = {
        type: 'pigeon_post',
        role: 'admin',
        subject: 'Hello',
        layout_template: 'test_notify_email_layout',
        content_template_text: 'Hello'
      }

      warnings = described_class.validate_config(config)
      expect(warnings).to include("type 'pigeon_post' must be one of: email, sms")
    end

    it 'warns when importance is invalid' do
      config = {
        type: 'sms',
        importance: 'critical',
        phones: '+16175550100',
        layout_template: 'test_notify_sms_layout',
        content_template_text: 'Hello'
      }

      warnings = described_class.validate_config(config)
      expect(warnings).to include("importance 'critical' must be one of: Promotional, Transactional")
    end

    it 'warns when subject is missing for email type' do
      config = {
        type: 'email',
        role: 'admin',
        layout_template: 'test_notify_email_layout',
        content_template_text: 'Hello'
      }

      warnings = described_class.validate_config(config)
      expect(warnings).to include('subject is required when type is email')
    end

    it 'does not require subject for sms type' do
      config = {
        type: 'sms',
        phones: '+16175550100',
        layout_template: 'test_notify_sms_layout',
        content_template_text: 'Hello'
      }

      warnings = described_class.validate_config(config)
      expect(warnings).not_to include('subject is required when type is email')
    end

    it 'warns when layout_template is missing' do
      config = {
        type: 'email',
        subject: 'Subject',
        content_template_text: 'Hello'
      }

      warnings = described_class.validate_config(config)
      expect(warnings).to include('layout_template is required')
    end

    it 'warns when layout_template does not exist' do
      config = {
        type: 'email',
        subject: 'Subject',
        layout_template: 'nonexistent_layout',
        content_template_text: 'Hello'
      }

      warnings = described_class.validate_config(config)
      expect(warnings).to include("layout_template 'nonexistent_layout' not found for email")
    end

    it 'warns when both content_template and content_template_text are missing' do
      config = {
        type: 'email',
        subject: 'Subject',
        layout_template: 'test_notify_email_layout'
      }

      warnings = described_class.validate_config(config)
      expect(warnings).to include('content_template or content_template_text is required')
    end

    it 'warns when content_template does not exist' do
      config = {
        type: 'email',
        subject: 'Subject',
        layout_template: 'test_notify_email_layout',
        content_template: 'nonexistent_content'
      }

      warnings = described_class.validate_config(config)
      expect(warnings).to include("content_template 'nonexistent_content' not found for email")
    end

    it 'validates arrays of notify configurations' do
      configs = [
        {
          type: 'email',
          subject: 'Valid Subject',
          layout_template: 'test_notify_email_layout',
          content_template: 'test_notify_email_content'
        },
        {
          type: 'email',
          layout_template: 'nonexistent_layout',
          content_template_text: 'Hello'
        }
      ]

      warnings = described_class.validate_config(configs)
      expect(warnings).to include('subject is required when type is email')
      expect(warnings).to include("layout_template 'nonexistent_layout' not found for email")
    end

    context 'role existence validation (issue #1374)' do
      let(:base_config) do
        {
          type: 'email',
          subject: 'Test',
          layout_template: 'test_notify_email_layout',
          content_template: 'test_notify_email_content'
        }
      end

      it 'produces no role warning for a known literal role' do
        config = base_config.merge(role: @existing_role_name)
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('role') }).to be true
      end

      it 'warns for an unknown literal role' do
        config = base_config.merge(role: 'completely_nonexistent_role_xyz')
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('role') && w.include?('completely_nonexistent_role_xyz') }).to be true
      end

      it 'skips validation for a template substitution role' do
        config = base_config.merge(role: '{{dynamic_role}}')
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('role') }).to be true
      end

      it 'skips validation for a conditional hash role' do
        config = base_config.merge(role: { this: { select_role: 'return_value' } })
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('role') }).to be true
      end

      it 'validates each literal entry in an array of roles' do
        config = base_config.merge(role: [@existing_role_name, 'nonexistent_role_abc', '{{dynamic_role}}'])
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?(@existing_role_name) }).to be true
        expect(warnings.any? { |w| w.include?('role') && w.include?('nonexistent_role_abc') }).to be true
        expect(warnings.none? { |w| w.include?('dynamic_role') }).to be true
      end

      it 'uses an explicit app_type in the notify config for role existence' do
        config = base_config.merge(role: @other_role_name, app_type: @other_app_type.id)

        warnings = described_class.validate_config(config)

        expect(warnings).not_to include("role '#{@other_role_name}' is not a known active role")
      end
    end

    context 'users existence validation (issue #1374)' do
      let(:base_config) do
        {
          type: 'email',
          subject: 'Test',
          layout_template: 'test_notify_email_layout',
          content_template: 'test_notify_email_content'
        }
      end

      it 'produces no user warning for known literal user IDs, including numeric strings' do
        config = base_config.merge(users: [@test_user.id, @test_user2.id.to_s])
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('user') }).to be true
      end

      it 'warns for an unknown literal user ID' do
        config = base_config.merge(users: -999)
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('user') && w.include?('-999') }).to be true
      end

      it 'warns for an expired literal user ID' do
        expired_user, = create_user
        expired_user.current_admin = @admin
        expired_user.update_columns(expire_datetime: 1.day.ago)
        config = base_config.merge(users: expired_user.id)
        warnings = described_class.validate_config(config)
        expect(warnings).to include(a_string_matching(/users.*expired/))
      end

      it 'skips validation for a template substitution user' do
        config = base_config.merge(users: '{{calculated_user_id}}')
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('user') }).to be true
      end

      it 'skips validation for a conditional hash user' do
        config = base_config.merge(users: { this: { user_id: 'return_value' } })
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('user') }).to be true
      end

      it 'validates each literal entry in an array of users' do
        config = base_config.merge(users: [@test_user.id, @test_user2.id, -888, '{{dynamic_id}}'])
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?(@test_user.id.to_s) }).to be true
        expect(warnings.none? { |w| w.include?(@test_user2.id.to_s) }).to be true
        expect(warnings.any? { |w| w.include?('user') && w.include?('-888') }).to be true
        expect(warnings.none? { |w| w.include?('dynamic_id') }).to be true
      end
    end

    context 'app_type reference validation (issue #1374)' do
      let(:base_config) do
        {
          type: 'email',
          subject: 'Test',
          layout_template: 'test_notify_email_layout',
          content_template: 'test_notify_email_content'
        }
      end

      it 'produces no app_type warning for a valid active app_type ID' do
        config = base_config.merge(app_type: @other_app_type.id)
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('app_type') }).to be true
      end

      it 'produces no app_type warning for a valid active app_type name' do
        config = base_config.merge(app_type: @other_app_type.name)
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('app_type') }).to be true
      end

      it 'warns for a non-existent app_type ID' do
        config = base_config.merge(app_type: -999)
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('app_type') && w.include?('-999') }).to be true
      end

      it 'warns for a non-existent app_type name' do
        config = base_config.merge(app_type: 'totally_nonexistent_app_xyz')
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('app_type') && w.include?('totally_nonexistent_app_xyz') }).to be true
      end

      it 'warns for a disabled app_type' do
        disabled_at = Admin::AppType.create!(name: "notify-val-disabled-#{SecureRandom.hex(4)}",
                                             label: 'Disabled AT', disabled: true, current_admin: @admin)
        config = base_config.merge(app_type: disabled_at.id)
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('app_type') }).to be true
      end

      it 'skips app_type validation for a {{substitution}}' do
        config = base_config.merge(app_type: '{{dynamic_app_type}}')
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('app_type') }).to be true
      end

      it 'skips app_type validation for a conditional hash' do
        config = base_config.merge(app_type: { this: { app_type_id: 'return_value' } })
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('app_type') }).to be true
      end
    end

    context 'user (singular context) reference validation (issue #1374)' do
      let(:base_config) do
        {
          type: 'email',
          subject: 'Test',
          layout_template: 'test_notify_email_layout',
          content_template: 'test_notify_email_content'
        }
      end

      it 'produces no user warning for a valid active user ID' do
        config = base_config.merge(user: @test_user.id)
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('user') && !w.include?('users') }).to be true
      end

      it 'produces no user warning for a valid active user email' do
        config = base_config.merge(user: @test_user.email)
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('user') && !w.include?('users') }).to be true
      end

      it 'warns for a non-existent user ID' do
        config = base_config.merge(user: -999)
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('user') && w.include?('-999') }).to be true
      end

      it 'warns for a non-existent user email' do
        config = base_config.merge(user: 'nonexistent-user-xyz@example.com')
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('user') && w.include?('nonexistent-user-xyz@example.com') }).to be true
      end

      it 'warns for a disabled user' do
        disabled_user, = create_user
        disabled_user.current_admin = @admin
        disabled_user.disabled = true
        disabled_user.save!
        config = base_config.merge(user: disabled_user.id)
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('user') && w.include?('disabled') }).to be true
      end

      it 'warns for an expired user' do
        expired_user, = create_user
        expired_user.current_admin = @admin
        expired_user.update_columns(expire_datetime: 1.day.ago)
        config = base_config.merge(user: expired_user.id)
        warnings = described_class.validate_config(config)
        expect(warnings.any? { |w| w.include?('user') && w.include?('expired') }).to be true
      end

      it 'skips user validation for a {{substitution}}' do
        config = base_config.merge(user: '{{dynamic_user}}')
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('user') && !w.include?('users') }).to be true
      end

      it 'skips user validation for a conditional hash' do
        config = base_config.merge(user: { this: { user_id: 'return_value' } })
        warnings = described_class.validate_config(config)
        expect(warnings.none? { |w| w.include?('user') && !w.include?('users') }).to be true
      end
    end
  end
end
