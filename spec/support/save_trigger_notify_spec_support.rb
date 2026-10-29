# frozen_string_literal: true

module SaveTriggerNotifySpecSupport
  AL_NAME_GEN_TEST = 'Gen Test ELT 2'

  def setup_notify_example
    disabled_user, = create_user
    disabled_user.disable!
    @user0, = create_user
    @u0 = @user0
    first_recipient, = create_user
    create_user
    let_user_create :player_contacts
    create_master
    ActivityLog::PlayerContactPhone.definition.update_tracker_events
    ActivityLog::PlayerContactElt2Test.definition.update_tracker_events

    @al = create_item
    setup_access @al.resource_name, resource_type: :activity_log_type, access: :create, user: @user

    layout_template = '<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div>{{main_content}}</div></body></html>'
    @layout = Admin::MessageTemplate.create!(
      name: 'test email layout', message_type: :email, template_type: :layout,
      template: layout_template, current_admin: @admin
    )
    @layout_sms = Admin::MessageTemplate.create!(
      name: 'test sms layout', message_type: :sms, template_type: :layout,
      template: '{{main_content}}', current_admin: @admin
    )
    @content = Admin::MessageTemplate.create!(
      name: 'test email content', message_type: :email, template_type: :content,
      template: '<p>This is some content.</p><p>Related to master_id {{master_id}}. This is a name: {{select_who}}.</p>',
      current_admin: @admin
    )

    latest_user_role_id = Admin::UserRole.order(id: :desc).limit(1).pluck(:id).first
    Admin::UserRole.where(role_name: 'test', app_type: first_recipient.app_type)
                   .update_all(role_name: "test-old-#{latest_user_role_id}")
    [first_recipient, @user, disabled_user].each do |user|
      Admin::UserRole.create!(app_type: first_recipient.app_type, user:, role_name: 'test', current_admin: @admin)
    end
    Admin::UserRole.create!(app_type: first_recipient.app_type, user: @user, role_name: 'test_2', current_admin: @admin)

    @at2 = Admin::AppType.create!(name: 'new-notify', label: 'Test Notify App', current_admin: @admin)
    Admin::UserRole.create!(app_type: @at2, user: @user0, role_name: 'test', current_admin: @admin)

    expect(Admin::UserRole.joins(:user).where(role_name: 'test', app_type: first_recipient.app_type)
                          .where('users.disabled is null or users.disabled = false').count).to eq 4

    @non_template_user_ids = [first_recipient.id, @user.id, disabled_user.id]
    @role_user_ids = @non_template_user_ids + [User.template_user.id]

    setup_stub(:sns_send_sms)
  end
end
