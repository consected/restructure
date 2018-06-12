require 'rails_helper'

RSpec.describe SaveTriggers::Notify, type: :model do

  include ModelSupport
  include ActivityLogSupport

  before :all do
    u1, _ = create_user
    create_user
    create_master
    @al = create_item

    # @activity_log = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player', select_who: 'user', master: @player_contact.master)

    t = '<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div>{{main_content}}</div></body></html>'
    @layout = Admin::MessageTemplate.create! name: 'test email layout', message_type: :email, template_type: :layout, template: t, current_admin: @admin

    t = '<p>This is some content.</p><p>Related to master_id {{master_id}}. This is a name: {{select_who}}.</p>'
    @content = Admin::MessageTemplate.create! name: 'test email content', message_type: :email, template_type: :content, template: t, current_admin: @admin

    Admin::UserRole.where(role_name: 'test').delete_all
    Admin::UserRole.create! app_type: u1.app_type, user: u1, role_name: 'test', current_admin: @admin
    Admin::UserRole.create! app_type: u1.app_type, user: @user, role_name: 'test', current_admin: @admin

    expect(Admin::UserRole.where(role_name: 'test').count).to eq 2

    @role_user_ids = [u1.id, @user.id]

  end



  it "generates a message notification and job" do
    config = {
      type: "email",
      role: "test",
      layout_template: @layout.name,
      content_template: @content.name,
      subject: "subject text"
    }

    expect(Admin::UserRole.where(role_name: 'test').count).to eq 2

    @trigger = SaveTriggers::Notify.new config, @al

    expect(@trigger.receiving_user_ids.sort).to eq @role_user_ids.sort

    last_mn = MessageNotification.order(id: :desc).first
    # last_dj = Delayed::Job.order(id: :desc).first

    @trigger.perform

    new_mn = MessageNotification.order(id: :desc).first
    # new_dj = Delayed::Job.order(id: :desc).first

    expect(last_mn).not_to eq new_mn

    new_mn.generate
    res = new_mn.generated_text
    expected_name = @al.select_who
    master = @al.master
    expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content.</p><p>Related to master_id #{master.id}. This is a name: #{expected_name}.</p></div></body></html>"

    expect(res).to eq expected_text


    # expect(last_dj).not_to eq new_dj

  end

end
