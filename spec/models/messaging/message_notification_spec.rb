# frozen_string_literal: true

# Tests for Messaging::MessageNotification
# Covers message generation, template rendering, recipient handling (email/SMS/records),
# calendar invite attachment resolution (#953), NfsStore file attachment resolution (#954),
# and NotificationMailer integration with attachment support.

require 'rails_helper'

RSpec.describe Messaging::MessageNotification, type: :model do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport
  include BulkMsgSupport
  include TestNoMasterDmRecSupport

  def mock_notification_mailer
    mailer = double('mailer', deliver_now: true)
    allow(NotificationMailer).to receive(:send_message_notification) { mailer }
  end

  def unmock_notification_mailer
    allow(NotificationMailer).to receive(:send_message_notification).and_call_original
  end

  def setup_messaging_test
    create_admin
    @rec_user, = create_user
    create_user
    seed_database
    ActivityLog.define_models
    setup_access :player_contacts
    create_item(data: rand(10_000_000_000_000_000), rank: 10)
    @player_contact.master.current_user = @user
    expect(@player_contact.master).to be_a Master
    expect(@player_contact.master_user).to be_a User

    setup_access :activity_log__player_contact_phones
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type
    setup_access :activity_log__player_contact_phone__blank_log, resource_type: :activity_log_type
    setup_access :activity_log__player_contact_phones, user: @user
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, user: @user
    setup_access :activity_log__player_contact_phone__blank_log, resource_type: :activity_log_type, user: @user
    @activity_log = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player', select_who: 'user', master: @player_contact.master)

    t = '<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div>{{main_content}}</div></body></html>'
    @layout = Admin::MessageTemplate.create! name: 'test email layout', message_type: :email, template_type: :layout, template: t, current_admin: @admin

    t = <<~END_TEXT
      Test SMS

      {{main_content}}
    END_TEXT

    @layout_sms = Admin::MessageTemplate.create! name: 'test sms layout', message_type: :sms, template_type: :layout, template: t, current_admin: @admin

    t = '<p>This is some content.</p><p>Related to master_id {{master_id}}. This is a name: {{select_who}}.</p>'
    @content = Admin::MessageTemplate.create! name: 'test email content', message_type: :email, template_type: :content, template: t, current_admin: @admin
  end

  describe 'message notification generation and handling' do
    before :example do
      setup_messaging_test
      mock_notification_mailer
      Delayed::Job.delete_all
    end

    after :example do
      unmock_notification_mailer
    end

    it 'generates a message' do
      master = @activity_log.master

      layout = @layout
      content = @content

      expect do
        Messaging::MessageNotification.create! app_type: @user.app_type, user: @user, recipient_user_ids: [@rec_user], layout_template_name: layout.name,
                                               item_type: @activity_log.class.name, item_id: @activity_log.id, master:, message_type: :email,
                                               subject: 'Test Subject'
      end.to raise_error ActiveRecord::RecordInvalid # for no content template

      mn = Messaging::MessageNotification.create! app_type: @user.app_type, user: @user, recipient_user_ids: [@rec_user], layout_template_name: layout.name,
                                                  content_template_name: content.name, item_type: @activity_log.class.name, item_id: @activity_log.id, master:, message_type: :email,
                                                  subject: 'Test Subject'

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
                                               item_type: @activity_log.class.name, item_id: @activity_log.id, master:, message_type: :email,
                                               subject: 'Test Subject'
      end.to raise_error ActiveRecord::RecordInvalid # for no content template

      mn = Messaging::MessageNotification.create! app_type: @user.app_type, user: @user, recipient_user_ids: [@rec_user], layout_template_name: layout.name,
                                                  content_template_text: t, item_type: @activity_log.class.name, item_id: @activity_log.id, master:, message_type: :email,
                                                  subject: 'Test Subject'

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
                                                  content_template_text: t, item_type: @activity_log.class.name, item_id: @activity_log.id, master:, message_type: :email,
                                                  subject: 'Test Subject'

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
      expect(mn.master_id).to eq master.id

      expect(mn.data)
      expect(mn.from_user_email).to eq Settings::NotificationsFromEmail || mn.user.email
    end

    it 'allows item models with no_master_association to work correctly' do
      setup_test_no_master_dm_rec_dynamic_model
      dm = create_test_no_master_dm_rec(sample_test_no_master_dm_rec_attrs)

      t = '<p>This is some new content in a text template.</p><p>Related to a dynamic model {{data}}. This is the info: {{info}}.</p>'

      layout = @layout

      mn = Messaging::MessageNotification.create! app_type: @user.app_type, user: @user, recipient_user_ids: [@rec_user], layout_template_name: layout.name,
                                                  content_template_text: t, item_type: dm.class.name, item_id: dm.id, master: nil, message_type: :email,
                                                  subject: 'Test Subject'

      mn.handle_notification_now logger: Delayed::Worker.logger,
                                 for_item: dm,
                                 on_complete_config: nil

      mn.reload
      res = mn.generated_text
      @activity_log.select_who

      expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some new content in a text template.</p><p>Related to a dynamic model #{dm.data}. This is the info: #{dm.info}.</p></div></body></html>"

      expect(res).to eq expected_text
      expect(mn.generated_content).to eq res

      expect(mn.recipient_data).not_to be_empty
      expect(mn.recipient_data).to be_a Array
      expect(mn.recipient_data.first).to be_a String
      expect(mn.recipient_data.first).to eq @rec_user.email
      expect(mn.master_id).to be nil

      expect(mn.data)
      expect(mn.from_user_email).to eq Settings::NotificationsFromEmail || mn.user.email
    end

    it 'sets up a notification to be sent, where substitution data is a hash' do
      t = '<p>This is some new content in a text template.</p><p>Related to another master_id {{master_id}}. This is a name: {{select_who}}.</p>'

      @activity_log.master
      layout = @layout

      # NOTE: do not specify app_type when using data rather than setting an item
      mn = Messaging::MessageNotification.create! user: @user, recipient_user_ids: [@rec_user], layout_template_name: layout.name,
                                                  content_template_text: t, message_type: :email,
                                                  subject: 'Test Subject',
                                                  data: {
                                                    master_id: 1234,
                                                    select_who: 'henry anderson'
                                                  }

      mn.handle_notification_now logger: Delayed::Worker.logger

      mn.reload
      res = mn.generated_text
      @activity_log.select_who

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
                                                  content_template_text: t, item_type: @activity_log.class.name, item_id: @activity_log.id, master:, message_type: :email,
                                                  subject: 'Test Subject',
                                                  from_user_email: { address: 'test@testemail.test', display_name: 'Test Email' }

      expect(mn.from_user_email).to eq 'Test Email <test@testemail.test>'

      mn = Messaging::MessageNotification.create! app_type: @user.app_type, user: @user, recipient_user_ids: [@rec_user], layout_template_name: layout.name,
                                                  content_template_text: t, item_type: @activity_log.class.name, item_id: @activity_log.id, master:, message_type: :email,
                                                  subject: 'Test Subject',
                                                  from_user_email: 'test@testemail2.test'

      expect(mn.from_user_email).to eq 'test@testemail2.test'
    end

    it 'uses extra_substitutions as data' do
      t = '<p>This is some new content in a text template.</p><p>Related to another master_id {{master_id}}. This is a name: {{select_who}}. Footer has {{extra_substitutions.data1}}</p>'

      master = @activity_log.master
      layout = @layout

      mn = Messaging::MessageNotification.create! app_type: @user.app_type, user: @user, recipient_user_ids: [@rec_user], layout_template_name: layout.name,
                                                  content_template_text: t, item_type: @activity_log.class.name, item_id: @activity_log.id, master:, message_type: :email,
                                                  subject: 'Test Subject',
                                                  from_user_email: { address: 'test@testemail.test', display_name: 'Test Email' },
                                                  extra_substitutions: { data1: 'es-data-one', data2: 'es-data-two' }
      mn.generate

      expect(mn.generated_text).to eq "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some new content in a text template.</p><p>Related to another master_id #{master.id}. This is a name: #{@activity_log.select_who}. Footer has es-data-one</p></div></body></html>"
    end

    it 'uses avoids producing HTML for SMS messages' do
      t = <<~END_TEXT
        This is some new content in a text template.

        Related to another master_id {{master_id}}. This is a name: {{select_who}}.
      END_TEXT

      master = @activity_log.master
      layout = @layout_sms

      mn = Messaging::MessageNotification.create! app_type: @user.app_type, user: @user, recipient_user_ids: [@rec_user], layout_template_name: layout.name,
                                                  content_template_text: t, item_type: @activity_log.class.name, item_id: @activity_log.id, master:, message_type: :sms

      mn.generate

      exp_text = <<~END_TEXT
        Test SMS

        This is some new content in a text template.

        Related to another master_id #{master.id}. This is a name: #{@activity_log.select_who}.

      END_TEXT

      expect(mn.generated_text).to eq exp_text
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
                                                  content_template_text: t, item_type: @activity_log.class.name, item_id: @activity_log.id, master:, message_type: :email,
                                                  subject: 'Test Subject'

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
        testcnx.execute <<~END_SQL
          insert into ml_app.message_notifications (app_type_id, user_id, recipient_user_ids, layout_template_name, content_template_name, item_type, item_id, master_id, message_type, created_at, updated_at)
          values (#{@user.app_type_id}, #{@user.id}, '{#{@rec_user.id}}', '#{layout.name}', '#{content.name}', '#{@activity_log.class.name}', '#{@activity_log.id}', #{master.id}, 'email', now(), now() );
        END_SQL
        # Check that the new message notification record has been entered into the database and can be read
        new_mn_id = Messaging::MessageNotification.last.id
        # puts "Previous #{mn_id} and new one to be processed #{new_mn_id}"
        expect(mn_id).not_to eq new_mn_id
      end

      sleep 1

      nil
      10.times.each do
        break if Delayed::Job.none?

        sleep 2
        # puts "Waiting again"
      end

      # This doesn't work in test environment since delayed job doesn't run. Need to mock to test this
      # res = testcnx.exec_query "select status, id from  ml_app.message_notifications order by id desc limit 1;"
      # expect(res.rows.first[0]).to eq 'complete'
    end
  end

  describe 'stored XSS protection' do
    before :example do
      setup_messaging_test
      mock_notification_mailer
      Delayed::Job.delete_all
    end

    after :example do
      unmock_notification_mailer
    end

    it 'raises when email notification generation renders dangerous HTML' do
      master = @activity_log.master

      mn = Messaging::MessageNotification.create! app_type: @user.app_type, user: @user,
                                                  recipient_user_ids: [@rec_user],
                                                  layout_template_name: @layout.name,
                                                  content_template_text: '<p>{{payload}}</p>',
                                                  item_type: @activity_log.class.name,
                                                  item_id: @activity_log.id,
                                                  master:,
                                                  message_type: :email,
                                                  subject: 'Test Subject',
                                                  data: { payload: '<img src="x" onerror="alert(1)">' }

      expect do
        mn.generate
      end.to raise_error(FphsException, /disallowed tag or attribute/)
    end

    it 'allows SMS generation to include script-like plain text' do
      master = @activity_log.master

      mn = Messaging::MessageNotification.create! app_type: @user.app_type, user: @user,
                                                  recipient_user_ids: [@rec_user],
                                                  layout_template_name: @layout_sms.name,
                                                  content_template_text: '<script>alert(1)</script>',
                                                  item_type: @activity_log.class.name,
                                                  item_id: @activity_log.id,
                                                  master:,
                                                  message_type: :sms

      expect { mn.generate }.not_to raise_error
      expect(mn.generated_text).to include '<script>alert(1)</script>'
    end
  end

  describe 'validations (issue #1370)' do
    before :example do
      setup_messaging_test
    end

    it 'validates message_type presence and inclusion' do
      mn = Messaging::MessageNotification.new(
        app_type: @user.app_type, user: @user, recipient_user_ids: [@rec_user.id],
        layout_template_name: @layout.name, content_template_name: @content.name,
        item_type: @activity_log.class.name, item_id: @activity_log.id, master: @activity_log.master,
        subject: 'Subject', message_type: nil
      )
      expect(mn).not_to be_valid
      expect(mn.errors[:message_type]).to be_present

      mn.message_type = 'invalid_type'
      expect(mn).not_to be_valid
      expect(mn.errors[:message_type]).to be_present

      mn.message_type = 'email'
      expect(mn).to be_valid

      mn.message_type = 'sms'
      mn.layout_template_name = @layout_sms.name
      mn.content_template_name = nil
      mn.content_template_text = 'SMS body'
      expect(mn).to be_valid
    end

    it 'requires subject for email messages but not for sms' do
      mn = Messaging::MessageNotification.new(
        app_type: @user.app_type, user: @user, recipient_user_ids: [@rec_user.id],
        layout_template_name: @layout.name, content_template_name: @content.name,
        item_type: @activity_log.class.name, item_id: @activity_log.id, master: @activity_log.master,
        message_type: :email, subject: nil
      )
      expect(mn).not_to be_valid
      expect(mn.errors[:subject]).to be_present

      mn.subject = 'Now has subject'
      expect(mn).to be_valid

      mn_sms = Messaging::MessageNotification.new(
        app_type: @user.app_type, user: @user, recipient_user_ids: [@rec_user.id],
        layout_template_name: @layout_sms.name, content_template_text: 'SMS text',
        item_type: @activity_log.class.name, item_id: @activity_log.id, master: @activity_log.master,
        message_type: :sms, subject: nil
      )
      expect(mn_sms).to be_valid
    end

    it 'validates importance inclusion when present and normalizes case' do
      mn = Messaging::MessageNotification.new(
        app_type: @user.app_type, user: @user, recipient_user_ids: [@rec_user.id],
        layout_template_name: @layout.name, content_template_name: @content.name,
        item_type: @activity_log.class.name, item_id: @activity_log.id, master: @activity_log.master,
        message_type: :email, subject: 'Subject'
      )
      expect(mn).to be_valid

      mn.importance = 'promotional'
      expect(mn.importance).to eq('Promotional')
      expect(mn).to be_valid

      mn.importance = 'transactional'
      expect(mn.importance).to eq('Transactional')
      expect(mn).to be_valid

      mn.importance = 'critical'
      expect(mn).not_to be_valid
      expect(mn.errors[:importance]).to be_present
    end

    it 'validates layout_template exists and matches message_type' do
      mn = Messaging::MessageNotification.new(
        app_type: @user.app_type, user: @user, recipient_user_ids: [@rec_user.id],
        layout_template_name: 'nonexistent_layout', content_template_name: @content.name,
        item_type: @activity_log.class.name, item_id: @activity_log.id, master: @activity_log.master,
        message_type: :email, subject: 'Subject'
      )
      expect(mn).not_to be_valid
      expect(mn.errors[:layout_template_name]).to be_present

      # SMS layout template used for email message
      mn.layout_template_name = @layout_sms.name
      expect(mn).not_to be_valid
      expect(mn.errors[:layout_template_name]).to be_present

      mn.layout_template_name = @layout.name
      expect(mn).to be_valid
    end

    it 'validates content_template exists and matches message_type when specified' do
      mn = Messaging::MessageNotification.new(
        app_type: @user.app_type, user: @user, recipient_user_ids: [@rec_user.id],
        layout_template_name: @layout.name, content_template_name: 'nonexistent_content',
        item_type: @activity_log.class.name, item_id: @activity_log.id, master: @activity_log.master,
        message_type: :email, subject: 'Subject'
      )
      expect(mn).not_to be_valid
      expect(mn.errors[:content_template_name]).to be_present

      mn.content_template_name = @content.name
      expect(mn).to be_valid
    end
  end

  # Shared calendar invite test data for issue #953 specs
  let(:calendar_invite_data) do
    {
      'method' => 'REQUEST',
      'summary' => 'Study Review Meeting',
      'description' => 'Discuss study progress',
      'location' => 'Conference Room A',
      'dtstart' => '2026-04-01 10:00:00',
      'dtend' => '2026-04-01 11:00:00',
      'organizer' => 'organizer@example.com',
      'uid' => 'test-123@restructure',
      'sequence' => 0
    }
  end

  # Helper to create a message notification with optional calendar invite
  def create_test_notification(with_calendar_invite: false)
    attrs = {
      app_type: @user.app_type,
      user: @user,
      recipient_user_ids: [@rec_user],
      layout_template_name: @layout.name,
      content_template_name: @content.name,
      item_type: @activity_log.class.name,
      item_id: @activity_log.id,
      master: @activity_log.master,
      message_type: :email,
      subject: 'Test Subject'
    }
    attrs[:extra_substitutions] = { calendar_invite: calendar_invite_data } if with_calendar_invite
    Messaging::MessageNotification.create!(attrs)
  end

  describe 'resolve_attachments with calendar_invite (issue #953)' do
    before :example do
      setup_messaging_test
      mock_notification_mailer
    end

    after :example do
      unmock_notification_mailer
    end

    it 'reads calendar_invite from extra_substitutions, generates .ics content, and stores it back' do
      mn = create_test_notification(with_calendar_invite: true)

      mn.resolve_attachments
      resolved = mn.resolved_attachments

      expect(resolved).to be_a(Array)
      expect(resolved.length).to eq(1)
      attachment = resolved.first
      expect(attachment[:filename]).to eq('calendar.ics')
      expect(attachment[:mime_type]).to eq('text/calendar; method=REQUEST')
      expect(attachment[:content]).to include('BEGIN:VCALENDAR')
      expect(attachment[:content]).to include('METHOD:REQUEST')
      expect(attachment[:content]).to include('SUMMARY:Study Review Meeting')
      expect(attachment[:content]).to include('END:VCALENDAR')

      # Verify generated content is stored back in extra_substitutions
      mn.reload
      expect(mn.calendar_invite_data['generated_content']).to include('BEGIN:VCALENDAR')
    end
  end

  describe 'NotificationMailer attachment support (issue #953)' do
    before :example do
      setup_messaging_test
      change_setting('TestMail', true)
    end

    after :example do
      change_setting('TestMail', false)
    end

    it 'includes .ics attachment in the email when resolved_attachments is present' do
      mn = create_test_notification(with_calendar_invite: true)

      mn.generate
      mn.resolve_attachments

      # Build the mail message using the real mailer
      mail = NotificationMailer.send_message_notification(mn)

      # Verify the mail has an attachment
      expect(mail.attachments.size).to eq(1)
      attachment = mail.attachments['calendar.ics']
      expect(attachment).not_to be_nil
      expect(attachment.content_type).to include('text/calendar')
      expect(attachment.body.decoded).to include('BEGIN:VCALENDAR')
      expect(attachment.body.decoded).to include('METHOD:REQUEST')
    end

    it 'sends email without attachments when no resolved_attachments present (backward compatibility)' do
      mn = create_test_notification(with_calendar_invite: false)

      mn.generate

      # Build the mail message using the real mailer
      mail = NotificationMailer.send_message_notification(mn)

      # Verify the mail has no attachments
      expect(mail.attachments.size).to eq(0)
      expect(mail.body.to_s).to include('This is some content')
    end
  end

  describe 'resolve_attachments with NfsStore file attachments (issue #954)' do
    before :example do
      setup_messaging_test
      mock_notification_mailer
    end

    after :example do
      unmock_notification_mailer
    end

    it 'resolves NfsStore file attachments from extra_substitutions, reads file content, and builds attachment hash' do
      # Create a mock stored file
      stored_file = instance_double(
        NfsStore::Manage::StoredFile,
        id: 101,
        file_name: 'report.pdf',
        content_type: 'application/pdf',
        retrieval_path: Rails.root.join('tmp/agent-tmp/test_report.pdf').to_s
      )

      # Create a temporary file to read
      FileUtils.mkdir_p(Rails.root.join('tmp/agent-tmp'))
      File.write(Rails.root.join('tmp/agent-tmp/test_report.pdf'), 'PDF file content here')

      allow(NfsStore::Manage::StoredFile).to receive(:find_by)
        .with(nfs_store_container_id: 42, path: 'reports', file_name: 'report.pdf')
        .and_return(stored_file)
      allow(stored_file).to receive(:current_user=)
      allow(stored_file).to receive(:container).and_return(
        instance_double(NfsStore::Manage::Container, current_user: nil, 'current_user=' => nil)
      )

      mn = create_test_notification(with_calendar_invite: false)
      mn.extra_substitutions = {
        attachments: [
          { 'container_id' => 42, 'path' => 'reports', 'file_name' => 'report.pdf' }
        ]
      }.to_yaml
      mn.save!

      mn.resolve_attachments
      resolved = mn.resolved_attachments

      expect(resolved).to be_a(Array)
      # Find the NfsStore attachment (not calendar)
      nfs_attachment = resolved.find { |a| a[:filename] == 'report.pdf' }
      expect(nfs_attachment).not_to be_nil
      expect(nfs_attachment[:mime_type]).to eq('application/pdf')
      expect(nfs_attachment[:content]).to eq('PDF file content here')

      # Verify reference (not content) is stored back in extra_substitutions
      mn.reload
      es_data = YAML.safe_load(mn.extra_substitutions, permitted_classes: [Symbol])
      att_ref = es_data['attachments'].first
      expect(att_ref['stored_file_id']).to eq(101)
      expect(att_ref['content_type']).to eq('application/pdf')
      # File content should NOT be stored in DB
      expect(att_ref).not_to have_key('content')
    ensure
      FileUtils.rm_f(Rails.root.join('tmp/agent-tmp/test_report.pdf'))
    end

    it 'handles NfsStore attachment alongside calendar_invite attachment' do
      stored_file = instance_double(
        NfsStore::Manage::StoredFile,
        id: 202,
        file_name: 'data.csv',
        content_type: 'text/csv',
        retrieval_path: Rails.root.join('tmp/agent-tmp/test_data.csv').to_s
      )

      FileUtils.mkdir_p(Rails.root.join('tmp/agent-tmp'))
      File.write(Rails.root.join('tmp/agent-tmp/test_data.csv'), 'col1,col2\nval1,val2')

      allow(NfsStore::Manage::StoredFile).to receive(:find_by)
        .with(nfs_store_container_id: 10, path: '', file_name: 'data.csv')
        .and_return(stored_file)
      allow(stored_file).to receive(:current_user=)
      allow(stored_file).to receive(:container).and_return(
        instance_double(NfsStore::Manage::Container, current_user: nil, 'current_user=' => nil)
      )

      mn = create_test_notification(with_calendar_invite: true)
      # Merge NfsStore attachments into the existing extra_substitutions
      es_data = YAML.safe_load(mn.extra_substitutions, permitted_classes: [Symbol])
      es_data['attachments'] = [
        { 'container_id' => 10, 'path' => '', 'file_name' => 'data.csv' }
      ]
      mn.extra_substitutions = es_data.to_yaml
      mn.save!

      # Clear memoized extra_substitutions_data so resolve_attachments sees updated data
      mn.extra_substitutions_data = nil

      mn.resolve_attachments
      resolved = mn.resolved_attachments

      # Should have both calendar invite and NfsStore file attachments
      expect(resolved.length).to eq(2)
      calendar_att = resolved.find { |a| a[:filename] == 'calendar.ics' }
      nfs_att = resolved.find { |a| a[:filename] == 'data.csv' }
      expect(calendar_att).not_to be_nil
      expect(nfs_att).not_to be_nil
      expect(nfs_att[:mime_type]).to eq('text/csv')
    ensure
      FileUtils.rm_f(Rails.root.join('tmp/agent-tmp/test_data.csv'))
    end

    it 'raises an error when NfsStore file is not found' do
      allow(NfsStore::Manage::StoredFile).to receive(:find_by)
        .with(nfs_store_container_id: 999, path: '', file_name: 'missing.pdf')
        .and_return(nil)

      mn = create_test_notification(with_calendar_invite: false)
      mn.extra_substitutions = {
        attachments: [
          { 'container_id' => 999, 'path' => '', 'file_name' => 'missing.pdf' }
        ]
      }.to_yaml
      mn.save!

      expect { mn.resolve_attachments }.to raise_error(FphsException, /NfsStore file not found/)
    end

    it 'raises an error when NfsStore file has no retrieval_path' do
      stored_file = instance_double(
        NfsStore::Manage::StoredFile,
        id: 303,
        file_name: 'no_access.pdf',
        content_type: 'application/pdf',
        retrieval_path: nil
      )

      allow(NfsStore::Manage::StoredFile).to receive(:find_by)
        .with(nfs_store_container_id: 50, path: '', file_name: 'no_access.pdf')
        .and_return(stored_file)
      allow(stored_file).to receive(:current_user=)
      allow(stored_file).to receive(:container).and_return(
        instance_double(NfsStore::Manage::Container, current_user: nil, 'current_user=' => nil)
      )

      mn = create_test_notification(with_calendar_invite: false)
      mn.extra_substitutions = {
        attachments: [
          { 'container_id' => 50, 'path' => '', 'file_name' => 'no_access.pdf' }
        ]
      }.to_yaml
      mn.save!

      expect { mn.resolve_attachments }.to raise_error(FphsException, /could not be retrieved/)
    end
  end
end
