# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messaging::MessageNotification, type: :model do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport
  include BulkMsgSupport

  def mock_notification_mailer
    mailer = double('mailer', deliver_now: true)
    allow(NotificationMailer).to receive(:send_message_notification) { mailer }
  end

  before :example do
    create_admin
    @rec_user, = create_user
    create_user
    seed_database
    ::ActivityLog.define_models
    setup_access :player_contacts
    create_item(data: rand(10_000_000_000_000_000), rank: 10)
    @player_contact.master.current_user = @user
    expect(@player_contact.master).to be_a Master
    expect(@player_contact.master_user).to be_a User

    setup_access :activity_log__player_contact_phones
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type
    setup_access :activity_log__player_contact_phone__blank, resource_type: :activity_log_type
    setup_access :activity_log__player_contact_phones, user: @user
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, user: @user
    setup_access :activity_log__player_contact_phone__blank, resource_type: :activity_log_type, user: @user
    @activity_log = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player', select_who: 'user', master: @player_contact.master)

    t = '<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div>{{main_content}}</div></body></html>'
    @layout = Admin::MessageTemplate.create! name: 'test email layout', message_type: :email, template_type: :layout, template: t, current_admin: @admin

    t = '<p>This is some content.</p><p>Related to master_id {{master_id}}. This is a name: {{select_who}}.</p>'
    @content = Admin::MessageTemplate.create! name: 'test email content', message_type: :email, template_type: :content, template: t, current_admin: @admin

    mock_notification_mailer
    Delayed::Job.delete_all
  end

  it 'generates a message' do
    master = @activity_log.master

    layout = @layout
    content = @content

    expect do
      Messaging::MessageNotification.create! app_type: @user.app_type, user: @user, recipient_user_ids: [@rec_user], layout_template_name: layout.name,
                                             item_type: @activity_log.class.name, item_id: @activity_log.id, master: master, message_type: :email
    end.to raise_error ActiveRecord::RecordInvalid # for no content template

    mn = Messaging::MessageNotification.create! app_type: @user.app_type, user: @user, recipient_user_ids: [@rec_user], layout_template_name: layout.name,
                                                content_template_name: content.name, item_type: @activity_log.class.name, item_id: @activity_log.id, master: master, message_type: :email

    mn.generate

    res = mn.generated_text
    expected_name = @activity_log.select_who

    expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content.</p><p>Related to master_id #{master.id}. This is a name: #{expected_name}.</p></div></body></html>"

    expect(res).to eq expected_text
  end

  it 'generates a message from a text template' do
    t = '<p>This is some content in a text template.</p><p>Related to master_id {{master_id}}. This is a name: {{select_who}}.</p>'

    master = @activity_log.master
    layout = @layout

    expect do
      Messaging::MessageNotification.create! app_type: @user.app_type, user: @user, recipient_user_ids: [@rec_user], layout_template_name: layout.name,
                                             item_type: @activity_log.class.name, item_id: @activity_log.id, master: master, message_type: :email
    end.to raise_error ActiveRecord::RecordInvalid # for no content template

    mn = Messaging::MessageNotification.create! app_type: @user.app_type, user: @user, recipient_user_ids: [@rec_user], layout_template_name: layout.name,
                                                content_template_text: t, item_type: @activity_log.class.name, item_id: @activity_log.id, master: master, message_type: :email

    mn.generate

    res = mn.generated_text
    expected_name = @activity_log.select_who

    expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content in a text template.</p><p>Related to master_id #{master.id}. This is a name: #{expected_name}.</p></div></body></html>"

    expect(res).to eq expected_text
    expect(mn.generated_content).to eq res
  end

  it 'sets up a notification to be sent, recording appropriate information' do
    t = '<p>This is some new content in a text template.</p><p>Related to another master_id {{master_id}}. This is a name: {{select_who}}.</p>'

    master = @activity_log.master
    layout = @layout

    mn = Messaging::MessageNotification.create! app_type: @user.app_type, user: @user, recipient_user_ids: [@rec_user], layout_template_name: layout.name,
                                                content_template_text: t, item_type: @activity_log.class.name, item_id: @activity_log.id, master: master, message_type: :email

    mn.handle_notification_now logger: Delayed::Worker.logger,
                               for_item: @activity_log,
                               on_complete_config: nil

    mn.reload
    res = mn.generated_text
    expected_name = @activity_log.select_who

    expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some new content in a text template.</p><p>Related to another master_id #{master.id}. This is a name: #{expected_name}.</p></div></body></html>"

    expect(res).to eq expected_text
    expect(mn.generated_content).to eq res

    expect(mn.recipient_data).not_to be_empty
    expect(mn.recipient_data).to be_a Array
    expect(mn.recipient_data.first).to be_a String
    expect(mn.recipient_data.first).to eq @rec_user.email

    expect(mn.data)
    expect(mn.from_user_email).to eq Settings::NotificationsFromEmail || mn.user.email
  end

  it 'sets up a notification to be sent, where substitution data is a hash' do
    t = '<p>This is some new content in a text template.</p><p>Related to another master_id {{master_id}}. This is a name: {{select_who}}.</p>'

    master = @activity_log.master
    layout = @layout

    # NOTE: do not specify app_type when using data rather than setting an item
    mn = Messaging::MessageNotification.create! user: @user, recipient_user_ids: [@rec_user], layout_template_name: layout.name,
                                                content_template_text: t, message_type: :email,
                                                data: {
                                                  master_id: 1234,
                                                  select_who: 'henry anderson'
                                                }

    mn.handle_notification_now logger: Delayed::Worker.logger

    mn.reload
    res = mn.generated_text
    expected_name = @activity_log.select_who

    expected_text = '<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some new content in a text template.</p><p>Related to another master_id 1234. This is a name: henry anderson.</p></div></body></html>'

    expect(res).to eq expected_text
    expect(mn.generated_content).to eq res

    expect(mn.recipient_data).not_to be_empty
    expect(mn.recipient_data).to be_a Array
    expect(mn.recipient_data.first).to be_a String
    expect(mn.recipient_data.first).to eq @rec_user.email

    expect(mn.data)
    expect(mn.from_user_email).to eq Settings::NotificationsFromEmail || mn.user.email
  end

  it 'sets a from email address' do
    t = '<p>This is some new content in a text template.</p><p>Related to another master_id {{master_id}}. This is a name: {{select_who}}.</p>'

    master = @activity_log.master
    layout = @layout

    mn = Messaging::MessageNotification.create! app_type: @user.app_type, user: @user, recipient_user_ids: [@rec_user], layout_template_name: layout.name,
                                                content_template_text: t, item_type: @activity_log.class.name, item_id: @activity_log.id, master: master, message_type: :email,
                                                from_user_email: { address: 'test@testemail.test', display_name: 'Test Email' }

    expect(mn.from_user_email).to eq 'Test Email <test@testemail.test>'

    mn = Messaging::MessageNotification.create! app_type: @user.app_type, user: @user, recipient_user_ids: [@rec_user], layout_template_name: layout.name,
                                                content_template_text: t, item_type: @activity_log.class.name, item_id: @activity_log.id, master: master, message_type: :email,
                                                from_user_email: 'test@testemail2.test'

    expect(mn.from_user_email).to eq 'test@testemail2.test'
  end

  it 'uses extra_substitutions as data' do
    t = '<p>This is some new content in a text template.</p><p>Related to another master_id {{master_id}}. This is a name: {{select_who}}. Footer has {{extra_substitutions.data1}}</p>'

    master = @activity_log.master
    layout = @layout

    mn = Messaging::MessageNotification.create! app_type: @user.app_type, user: @user, recipient_user_ids: [@rec_user], layout_template_name: layout.name,
                                                content_template_text: t, item_type: @activity_log.class.name, item_id: @activity_log.id, master: master, message_type: :email,
                                                from_user_email: { address: 'test@testemail.test', display_name: 'Test Email' },
                                                extra_substitutions: { data1: 'es-data-one', data2: 'es-data-two' }
    mn.generate

    expect(mn.generated_text).to eq "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some new content in a text template.</p><p>Related to another master_id #{master.id}. This is a name: #{@activity_log.select_who}. Footer has es-data-one</p></div></body></html>"
  end

  it 'sets up a notification to be sent with an array of JSON representing recipient data' do
    setup_bulk_message_app
    populate_recipients

    t = '<p>This is some new content in a text template.</p><p>Related to another master_id {{master_id}}. This is a data: {{data}}.</p>'

    layout = @layout

    zbrs = DynamicModel::ZeusBulkMessageRecipient.active.order(id: :asc)
    expect(zbrs.count).to be > 1

    rd = zbrs.map do |u|
      {
        list_type: 'dynamic_model__zeus_bulk_message_recipients',
        id: u.id,
        default_country_code: 1
      }
    end

    expect(rd.length).to be > 1

    expect(zbrs.first.record_type).to eq 'player_contact'
    expect(zbrs.first.record_id).not_to be_nil

    data = zbrs.last.data
    master = PlayerContact.find(zbrs.last[:record_id]).master

    expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some new content in a text template.</p><p>Related to another master_id #{master.id}. This is a data: #{data}.</p></div></body></html>"

    mn = Messaging::MessageNotification.create! app_type: @user.app_type, user: @user, recipient_data: rd, layout_template_name: layout.name,
                                                content_template_text: t, item_type: @activity_log.class.name, item_id: @activity_log.id, master: master, message_type: :email

    mn.handle_notification_now logger: Delayed::Worker.logger,
                               for_item: @activity_log,
                               on_complete_config: nil

    res = mn.generated_text
    expect(res).to eq expected_text
    mn.reload

    expect(mn.generated_content).to eq res

    expect(mn.recipient_data).not_to be_empty
    expect(mn.recipient_data).to be_a Array
    expect(mn.recipient_data.first).to be_a String
    jrd = JSON.parse(mn.recipient_data.first)
    expect(jrd).to be_a Hash
    expect(jrd).to have_key 'list_type'
    expect(jrd['data']).to eq zbrs.first.data

    expect(zbrs.first.record_type).to eq 'player_contact'
    expect(zbrs.first.record_id).not_to be_nil

    expect(mn.recipient_hash_from_data.map { |m| m[:data] }.sort).to eq zbrs.pluck(:data).sort
  end

  it 'performs a background job to check for new notifications after an activity log has been created' do
    master = @activity_log.master

    layout = @layout
    content = @content

    # mn = nil

    # expect(Delayed::Job.count).to eq 0

    mn_id = Messaging::MessageNotification.last.id if Messaging::MessageNotification.last

    testcnx = ActiveRecord::Base.connection
    testcnx.transaction do
      @activity_log = @player_contact.activity_log__player_contact_phones.build(select_call_direction: 'from player', select_who: 'user', master: @player_contact.master)
      @activity_log.save!
      testcnx.execute <<EOF
  insert into ml_app.message_notifications (app_type_id, user_id, recipient_user_ids, layout_template_name, content_template_name, item_type, item_id, master_id, message_type, created_at, updated_at)
  values (#{@user.app_type_id}, #{@user.id}, '{#{@rec_user.id}}', '#{layout.name}', '#{content.name}', '#{@activity_log.class.name}', '#{@activity_log.id}', #{master.id}, 'email', now(), now() );
EOF
      # Check that the new message notification record has been entered into the database and can be read
      new_mn_id = Messaging::MessageNotification.last.id
      # puts "Previous #{mn_id} and new one to be processed #{new_mn_id}"
      expect(mn_id).not_to eq new_mn_id
    end

    sleep 1

    res = nil
    10.times.each do
      break if Delayed::Job.count == 0

      sleep 2
      # puts "Waiting again"
    end

    # This doesn't work in test environment since delayed job doesn't run. Need to mock to test this
    # res = testcnx.exec_query "select status, id from  ml_app.message_notifications order by id desc limit 1;"
    # expect(res.rows.first[0]).to eq 'complete'
  end
end
