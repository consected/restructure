# frozen_string_literal: true

require 'rails_helper'

# Specs for collecting notify layout/content template references in dynamic
# definition details, including nested triggers, missing templates, and values
# that cannot be resolved to a literal template name.
RSpec.describe 'admin/common_templates/_def_details_templates', type: :view do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include ExtraOptionConfigsSupport

  before_all do
    set_up_extra_options_configs alt_type: 'def_details_templates'
  end

  before do
    Admin::MessageTemplate.create!(
      name: 'notify_layout',
      message_type: :email,
      template_type: :layout,
      template: '{{main_content}}',
      current_admin: @admin
    )
    Admin::MessageTemplate.create!(
      name: 'notify_content',
      message_type: :email,
      template_type: :content,
      template: 'Notification content',
      current_admin: @admin
    )
  end

  it 'lists existing layout and content templates with badges and edit links' do
    all_configs_for(<<~YAML)
      default:
        fields:
          - test1
        save_trigger:
          on_create:
            notify:
              type: email
              subject: Notification
              layout_template: notify_layout
              content_template: notify_content
    YAML

    render partial: 'admin/common_templates/def_details_templates', locals: { object_instance: @dm }

    layout = Admin::MessageTemplate.find_by!(name: 'notify_layout')
    content = Admin::MessageTemplate.find_by!(name: 'notify_content')
    assert_select 'ul.al-reference-list li', count: 2
    assert_select 'ul.al-reference-list li span.badge', text: 'layout', count: 1
    assert_select 'ul.al-reference-list li span.badge', text: 'content', count: 1
    assert_select "ul.al-reference-list a[href='#{admin_message_templates_path(filter: { id: layout.id }, perform_action: 'edit')}'][target='_blank']",
                  text: /notify_layout/
    assert_select "ul.al-reference-list a[href='#{admin_message_templates_path(filter: { id: content.id }, perform_action: 'edit')}'][target='_blank']",
                  text: /notify_content/
  end

  it 'links a missing template to a new template form with its notify message type' do
    all_configs_for(<<~YAML)
      default:
        fields:
          - test1
        save_trigger:
          on_create:
            notify:
              type: email
              subject: Notification
              content_template: missing_content
    YAML

    render partial: 'admin/common_templates/def_details_templates', locals: { object_instance: @dm }

    expected_path = admin_message_templates_path(
      init_with: {
        message_type: 'email',
        template_type: 'content',
        category: @dm.category,
        name: 'missing_content'
      },
      perform_action: 'new'
    )
    assert_select 'ul.al-reference-list li span.badge', text: 'content'
    assert_select "ul.al-reference-list a[href='#{expected_path}'][target='_blank']",
                  text: /new content template for 'missing_content'/
  end

  it 'does not match a same-named template of a different message type to an email notify' do
    Admin::MessageTemplate.create!(
      name: 'sms_only_content',
      message_type: :sms,
      template_type: :content,
      template: 'SMS content',
      current_admin: @admin
    )

    all_configs_for(<<~YAML)
      default:
        fields:
          - test1
        save_trigger:
          on_update:
            notify:
              type: email
              subject: Notification
              content_template: sms_only_content
    YAML

    render partial: 'admin/common_templates/def_details_templates', locals: { object_instance: @dm }

    expected_path = admin_message_templates_path(
      init_with: {
        message_type: 'email',
        template_type: 'content',
        category: @dm.category,
        name: 'sms_only_content'
      },
      perform_action: 'new'
    )
    assert_select "ul.al-reference-list a[href='#{expected_path}'][target='_blank']",
                  text: /new content template for 'sms_only_content'/
    assert_select 'ul.al-reference-list a[href*="filter%5Bid%5D"]', count: 0
  end

  it 'lists a substitution-based template name as text without a link' do
    all_configs_for(<<~YAML)
      default:
        fields:
          - test1
        save_trigger:
          on_create:
            notify:
              type: email
              subject: Notification
              layout_template: "{{selected_layout}}"
              content_template:
                this:
                  field: selected_content
    YAML

    render partial: 'admin/common_templates/def_details_templates', locals: { object_instance: @dm }

    assert_select 'ul.al-reference-list li', count: 2
    assert_select 'ul.al-reference-list li', text: /{{selected_layout}}/
    assert_select 'ul.al-reference-list li', text: /selected_content/
    assert_select 'ul.al-reference-list li span.badge', text: 'layout'
    assert_select 'ul.al-reference-list li span.badge', text: 'content'
    assert_select 'ul.al-reference-list li a', count: 0
  end

  it 'finds nested transaction and batch references but lists duplicate references once' do
    all_configs_for(<<~YAML)
      default:
        fields:
          - test1
        save_trigger:
          on_create:
            transaction:
              notify:
                type: email
                subject: Notification
                layout_template: notify_layout
                content_template: notify_content
        batch_trigger:
          on_record:
            notify:
              type: email
              subject: Notification
              layout_template: notify_layout
              content_template: notify_content
    YAML

    render partial: 'admin/common_templates/def_details_templates', locals: { object_instance: @dm }

    assert_select 'ul.al-reference-list li', count: 2
    assert_select 'ul.al-reference-list li', text: /notify_layout/, count: 1
    assert_select 'ul.al-reference-list li', text: /notify_content/, count: 1
  end

  it 'lists notify templates from lifecycle hooks but ignores notify keys inside trigger data' do
    all_configs_for(<<~YAML)
      default:
        fields:
          - test1
        save_trigger:
          on_update:
            notify:
              type: email
              subject: Notification
              content_template: notify_content
              on_complete:
                notify:
                  type: email
                  subject: Follow up
                  content_template: follow_up_content
            update_this:
              notify:
                type: email
                content_template: payload_only_content
    YAML

    render partial: 'admin/common_templates/def_details_templates', locals: { object_instance: @dm }

    assert_select 'ul.al-reference-list li', count: 2
    assert_select 'ul.al-reference-list li a', text: /notify_content/
    assert_select 'ul.al-reference-list li', text: /follow_up_content/
    expect(rendered).not_to include('payload_only_content')
  end

  it 'does not link an unresolved notify type to a same-named dialog or plain template' do
    Admin::MessageTemplate.create!(
      name: 'dialog_named_content',
      message_type: :dialog,
      template_type: :content,
      template: 'Dialog content',
      current_admin: @admin
    )

    all_configs_for(<<~YAML)
      default:
        fields:
          - test1
        save_trigger:
          on_create:
            notify:
              type: "{{message_type}}"
              subject: Notification
              content_template: dialog_named_content
    YAML

    render partial: 'admin/common_templates/def_details_templates', locals: { object_instance: @dm }

    assert_select 'ul.al-reference-list a', text: /new content template for 'dialog_named_content'/
    assert_select 'ul.al-reference-list a[href*="filter%5Bid%5D"]', count: 0
  end

  it 'omits an unknown notify message type from the create-template parameters' do
    all_configs_for(<<~YAML)
      default:
        fields:
          - test1
        save_trigger:
          on_create:
            notify:
              type: "{{message_type}}"
              content_template: missing_content
              content_template_text: fallback content
    YAML

    render partial: 'admin/common_templates/def_details_templates', locals: { object_instance: @dm }

    expected_path = admin_message_templates_path(
      init_with: {
        template_type: 'content',
        category: @dm.category,
        name: 'missing_content'
      },
      perform_action: 'new'
    )
    assert_select "ul.al-reference-list a[href='#{expected_path}'][target='_blank']",
                  text: /new content template for 'missing_content'/
  end
end
