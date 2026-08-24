# frozen_string_literal: true

require 'rails_helper'

# Tests semantic validation of notify save trigger configurations.
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
  end
end
