require 'rails_helper'

RSpec.describe Messaging::MessageNotification, type: :model do


  include ModelSupport
  include PlayerContactSupport

  before :all do

    create_admin
    @rec_user, _ = create_user
    create_user
    seed_database
    ::ActivityLog.define_models
    setup_access :player_contacts
    create_item(data: rand(10000000000000000), rank: 10)
    @player_contact.master.current_user = @user
    expect( @player_contact.master).to be_a Master
    expect( @player_contact.master_user).to be_a User


    setup_access :activity_log__player_contact_phones
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type
    setup_access :activity_log__player_contact_phone__blank, resource_type: :activity_log_type
    @activity_log = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player', select_who: 'user', master: @player_contact.master)

    t = '<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div>{{main_content}}</div></body></html>'
    @layout = Admin::MessageTemplate.create! name: 'test email layout', message_type: :email, template_type: :layout, template: t, current_admin: @admin

    t = '<p>This is some content.</p><p>Related to master_id {{master_id}}. This is a name: {{select_who}}.</p>'
    @content = Admin::MessageTemplate.create! name: 'test email content', message_type: :email, template_type: :content, template: t, current_admin: @admin

    Delayed::Job.delete_all

  end

  it "generates a message" do

    master = @activity_log.master

    layout = @layout
    content = @content

    mn = Messaging::MessageNotification.create! app_type: @user.app_type, user: @user, recipient_user_ids: [@rec_user], layout_template_name: layout.name,
    content_template_name: content.name, item_type: @activity_log.class.name, item_id: @activity_log.id, master: master, message_type: :email

    mn.generate

    res = mn.generated_text
    expected_name = @activity_log.select_who

    expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content.</p><p>Related to master_id <span>#{master.id}</span>. This is a name: <span>#{expected_name}<span>.</p></div></body></html>"

    expect(res).to eq expected_text
  end

  it "performs a background job to check for new notifications after an activity log has been created" do

    master = @activity_log.master

    layout = @layout
    content = @content

    mn = nil

    # expect(Delayed::Job.count).to eq 0

    mn_id = Messaging::MessageNotification.last.id if Messaging::MessageNotification.last

    testcnx = ActiveRecord::Base.establish_connection(:test).connection
testcnx.transaction do
  @activity_log = @player_contact.activity_log__player_contact_phones.build(select_call_direction: 'from player', select_who: 'user', master: @player_contact.master)
  @activity_log.save!
testcnx.execute <<EOF
  insert into ml_app.message_notifications (app_type_id, user_id, recipient_user_ids, layout_template_name, content_template_name, item_type, item_id, master_id, message_type, created_at, updated_at)
  values (#{@user.app_type_id}, #{@user.id}, '{#{@rec_user.id}}', '#{layout.name}', '#{content.name}', '#{@activity_log.class.name}', '#{@activity_log.id}', #{master.id}, 'email', now(), now() );
EOF
  # Check that the new message notification record has been entered into the database and can be read
  new_mn_id = Messaging::MessageNotification.last.id
  puts "Previous #{mn_id} and new one to be processed #{new_mn_id}"
  expect(mn_id).not_to eq new_mn_id
end

    sleep 1

    res = nil
    1..10.times.each do
       break if Delayed::Job.count == 0
      sleep 2
      puts "Waiting again"
    end

    res = testcnx.exec_query "select status, id from  ml_app.message_notifications order by id desc limit 1;"
    expect(res.rows.first[0]).to eq 'complete'


  end

end
