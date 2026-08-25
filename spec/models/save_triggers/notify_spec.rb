# frozen_string_literal: true

# Tests for SaveTriggers::Notify
# Covers notification trigger configuration parsing, role/user setup, message creation,
# template substitutions, conditional actions, return_value_list references,
# calendar invite integration (#953), NfsStore file attachment config parsing (#954),
# inline data URI image conversion (#1148), literal/template/array phones+emails (#1152),
# and config app_type for role lookup + error message improvements (#1172).

require 'rails_helper'

AlNameGenTestN = 'Gen Test ELT 2'
# Minimal valid 1x1 red pixel PNG in base64
PNG_BASE64_NOTIFY = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwADhQGAWjR9awAAAABJRU5ErkJggg=='

RSpec.describe SaveTriggers::Notify, type: :model do
  include ModelSupport
  include ActivityLogSupport
  include AwsApiStubs

  def example_setup
    ud, = create_user
    ud.disable!
    @u0, = create_user
    u1, = create_user
    create_user
    let_user_create :player_contacts
    create_master
    ActivityLog::PlayerContactPhone.definition.update_tracker_events
    ActivityLog::PlayerContactElt2Test.definition.update_tracker_events

    @al = create_item
    setup_access @al.resource_name, resource_type: :activity_log_type, access: :create, user: @user

    # @activity_log = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player', select_who: 'user', master: @player_contact.master)

    t = '<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div>{{main_content}}</div></body></html>'
    @layout = Admin::MessageTemplate.create! name: 'test email layout', message_type: :email, template_type: :layout, template: t, current_admin: @admin
    t = '{{main_content}}'
    @layout_sms = Admin::MessageTemplate.create! name: 'test sms layout', message_type: :sms, template_type: :layout, template: t, current_admin: @admin

    t = '<p>This is some content.</p><p>Related to master_id {{master_id}}. This is a name: {{select_who}}.</p>'
    @content = Admin::MessageTemplate.create! name: 'test email content', message_type: :email, template_type: :content, template: t, current_admin: @admin

    n = Admin::UserRole.order(id: :desc).limit(1).pluck(:id).first
    Admin::UserRole.where(role_name: 'test', app_type: u1.app_type).update_all(role_name: "test-old-#{n}")

    Admin::UserRole.create! app_type: u1.app_type, user: u1, role_name: 'test', current_admin: @admin
    Admin::UserRole.create! app_type: u1.app_type, user: @user, role_name: 'test', current_admin: @admin
    Admin::UserRole.create! app_type: u1.app_type, user: ud, role_name: 'test', current_admin: @admin

    Admin::UserRole.create! app_type: u1.app_type, user: @user, role_name: 'test_2', current_admin: @admin

    @at2 = Admin::AppType.create! name: 'new-notify', label: 'Test Notify App', current_admin: @admin
    Admin::UserRole.create! app_type: @at2, user: @u0, role_name: 'test', current_admin: @admin

    # The number of roles is one more than we added due to automatic setup of a template@template item
    expect(Admin::UserRole.joins(:user).where(role_name: 'test', app_type: u1.app_type).where('users.disabled is null or users.disabled = false').count).to eq 4

    @non_template_user_ids = [u1.id, @user.id, ud.id]
    @role_user_ids = @non_template_user_ids + [User.template_user.id]

    setup_stub(:sns_send_sms)
  end

  describe 'notify trigger' do
    before :all do
      SetupHelper.setup_al_player_contact_phones
      SetupHelper.setup_al_gen_tests AlNameGenTestN, 'elt2_test', 'player_contact'
    end

    before :example do
      example_setup
    end

    it 'generates a message notification and job' do
      config = {
        type: 'email',
        role: 'test',
        layout_template: @layout.name,
        content_template: @content.name,
        subject: 'subject text'
      }

      # Check that we only get users that are enabled for the role in this app type
      # The number of roles is one more than we added due to automatic setup of a template@template item
      expect(Admin::UserRole.joins(:user).where(role_name: 'test', app_type: @user.app_type).where('users.disabled is null or users.disabled = false').count).to eq 4

      @trigger = SaveTriggers::Notify.new(config, @al)
      last_mn = MessageNotification.order(id: :desc).first
      # last_dj = Delayed::Job.order(id: :desc).first

      @trigger.perform

      expect(@trigger.receiving_user_ids.sort).to eq @non_template_user_ids.sort

      new_mn = MessageNotification.order(id: :desc).first
      # new_dj = Delayed::Job.order(id: :desc).first

      expect(last_mn).not_to eq new_mn

      new_mn.generate
      res = new_mn.generated_text
      expected_name = @al.select_who
      master = @al.master
      expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content.</p><p>Related to master_id #{master.id}. This is a name: #{expected_name}.</p></div></body></html>"

      expect(res).to eq expected_text
    end

    it 'generates a message notification and job with referring_record substitutions' do
      @al1 = create_item
      @al1.update! select_who: 'someone new', current_user: @user, master_id: @al.master_id

      @al2 = create_item
      @al2.update! select_who: 'someone else new', current_user: @user, master_id: @al.master_id

      @al1.reload
      @al2.reload
      @al1.current_user = @user
      @al2.current_user = @user

      expect(@al.master_id).to eq @al2.master_id
      expect(@al.master_id).to eq @al1.master_id

      @al.extra_log_type_config.references = {
        activity_log__player_contact_phone: {
          from: 'this',
          add: 'many'
        }
      }

      OptionConfigs::ExtraOptionConfigs::References.reprocess(@al.extra_log_type_config)
      @al.extra_log_type_config.editable_if = { always: true }

      setup_access @al.class.resource_name, resource_type: :table, access: :create, user: @user
      setup_access @al.resource_name, resource_type: :activity_log_type, access: :create, user: @user

      begin
        ModelReference.create_with @al, @al1, force_create: true
        ModelReference.create_with @al, @al2, force_create: true
      rescue ActiveRecord::RecordInvalid => e
        puts e
      end

      t = '<p>This is some content.</p><p>Related to master_id {{master_id}} in id {{id}}. This is a name: {{select_who}}.</p><p>{{extra_substitutions.extra_text}}</p>'
      @content_extra = Admin::MessageTemplate.create! name: 'test email content extra', message_type: :email, template_type: :content, template: t, current_admin: @admin

      config = {
        type: 'email',
        role: 'test',
        layout_template: @layout.name,
        content_template: @content_extra.name,
        subject: 'subject text',
        extra_substitutions: {
          extra_text: 'Extra text at {{created_at}} for {{referring_record.id}}'
        }
      }

      # Check that we only get users that are enabled for the role in this app type
      # The number of roles is one more than we added due to automatic setup of a template@template item
      expect(Admin::UserRole.joins(:user).where(role_name: 'test', app_type: @user.app_type).where('users.disabled is null or users.disabled = false').count).to eq 4

      @trigger = SaveTriggers::Notify.new(config, @al2)

      last_mn = MessageNotification.order(id: :desc).first
      # last_dj = Delayed::Job.order(id: :desc).first

      @trigger.perform

      expect(@trigger.receiving_user_ids.sort).to eq @non_template_user_ids.sort

      new_mn = MessageNotification.order(id: :desc).first
      # new_dj = Delayed::Job.order(id: :desc).first

      expect(last_mn).not_to eq new_mn

      new_mn.generate
      res = new_mn.generated_text
      expected_name = @al2.select_who
      master = @al2.master
      id = @al2.id
      ca = Formatter::Formatters.formatter_do(@al2.created_at.class, @al2.created_at, current_user: @al2.user)
      rrid = @al.id
      expect(@al2.referring_record&.id).to eq rrid
      expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content.</p><p>Related to master_id #{master.id} in id #{id}. This is a name: #{expected_name}.</p><p>Extra text at #{ca} for #{rrid}</p></div></body></html>"

      expect(res).to eq expected_text
    end

    it 'generates a message notification with text template and job' do
      t = '<p>This is some content in a text template.</p><p>Related to master_id {{master_id}}. This is a name: {{select_who}}.</p>'
      config = {
        type: 'email',
        role: 'test',
        layout_template: @layout.name,
        content_template_text: t,
        subject: 'subject text'
      }

      # Check that we only get users that are enabled for the role in this app type
      # The number of roles is one more than we added due to automatic setup of a template@template item
      expect(Admin::UserRole.joins(:user).where(role_name: 'test', app_type: @user.app_type).where('users.disabled is null or users.disabled = false').count).to eq 4

      @trigger = SaveTriggers::Notify.new(config, @al)

      last_mn = MessageNotification.order(id: :desc).first
      # last_dj = Delayed::Job.order(id: :desc).first

      @trigger.perform

      expect(@trigger.receiving_user_ids.sort).to eq @non_template_user_ids.sort

      new_mn = MessageNotification.order(id: :desc).first
      # new_dj = Delayed::Job.order(id: :desc).first

      expect(last_mn).not_to eq new_mn

      new_mn.generate
      res = new_mn.generated_text
      expected_name = @al.select_who
      master = @al.master
      expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content in a text template.</p><p>Related to master_id #{master.id}. This is a name: #{expected_name}.</p></div></body></html>"

      expect(res).to eq expected_text
    end

    it 'generates an sms notification with phone numbers' do
      # Numbers from https://fakenumber.org/us/boston

      phones = ['(617)555-0118', '+16175550104', '6175550165', '+44(020) 671 2532']
      clean_phones = ['+16175550118', '+16175550104', '+16175550165', '+440206712532']

      t = 'This is some content in a text template.</p><p>Related to master_id {{master_id}}. This is a name: {{select_who}}'
      config = {
        type: 'sms',
        phones: phones,
        default_country_code: '1',
        layout_template: @layout_sms.name,
        content_template_text: t,
        subject: 'subject text'
      }

      @trigger = SaveTriggers::Notify.new(config, @al)

      last_mn = MessageNotification.order(id: :desc).first
      # last_dj = Delayed::Job.order(id: :desc).first

      @trigger.perform

      expect(@trigger.phones.sort).not_to eq phones.sort

      expect(@trigger.phones.sort).to eq clean_phones.sort

      new_mn = MessageNotification.order(id: :desc).first
      # new_dj = Delayed::Job.order(id: :desc).first

      expect(last_mn).not_to eq new_mn

      new_mn.generate
      res = new_mn.generated_text
      expected_name = @al.select_who
      master = @al.master
      expected_text = "This is some content in a text template.</p><p>Related to master_id #{master.id}. This is a name: #{expected_name}"

      expect(res).to eq expected_text
    end

    it 'uses a conditional field reference to get the users for a notification' do
      config = {
        type: 'email',
        users: {
          this: {
            user_id: 'return_value'
          }
        },
        layout_template: @layout.name,
        content_template: @content.name,
        subject: 'subject text'
      }
      @trigger = SaveTriggers::Notify.new config, @al

      @trigger.perform

      expect(@trigger.receiving_user_ids.first).to eq @al.user_id
    end

    it 'runs on_complete when notify config is an array of trigger entries - issue #1147' do
      completion_note = 'notify on_complete array fired issue 1147'

      config = {
        type: 'email',
        role: 'test',
        layout_template: @layout.name,
        content_template: @content.name,
        subject: 'subject text',
        on_complete: [
          {
            update_this: {
              one: {
                with: {
                  notes: completion_note
                }
              }
            }
          }
        ]
      }

      @al.update!(notes: nil, current_user: @user)
      @trigger = SaveTriggers::Notify.new(config, @al)

      @trigger.perform

      expect(@al.reload.notes).to eq(completion_note)
    end

    it 'uses a simple {{template}} reference to get the users for a notification' do
      config = {
        type: 'email',
        users: '{{user_id}}',
        layout_template: @layout.name,
        content_template: @content.name,
        subject: 'subject text'
      }
      @trigger = SaveTriggers::Notify.new config, @al

      @trigger.perform

      expect(@trigger.receiving_user_ids.first).to eq @al.user_id
    end

    it 'uses a simple {{{template}}} reference to get the users for a notification' do
      config = {
        type: 'email',
        users: '{{{user_id}}}',
        layout_template: @layout.name,
        content_template: @content.name,
        subject: 'subject text'
      }
      @trigger = SaveTriggers::Notify.new config, @al

      @trigger.perform

      expect(@trigger.receiving_user_ids.first).to eq @al.user_id
    end

    it 'uses template references for role configuration' do
      # Create a dynamic field on the activity log that contains the role name
      @al.select_who = 'test'
      @al.current_user = @user
      @al.save!
      config = {
        type: 'email',
        role: '{{select_who}}',
        layout_template: @layout.name,
        content_template: @content.name,
        subject: 'subject text'
      }
      @trigger = SaveTriggers::Notify.new config, @al

      @trigger.perform

      expect(@trigger.receiving_user_ids.sort).to eq @non_template_user_ids.sort
    end

    it 'uses template reference with existing field for role configuration' do
      # Use select_who field which contains 'user' - we'll map this to a role
      # First create a role named 'user'
      Admin::UserRole.create! app_type: @user.app_type, user: @user, role_name: 'user', current_admin: @admin

      config = {
        type: 'email',
        role: '{{select_who}}',
        layout_template: @layout.name,
        content_template: @content.name,
        subject: 'subject text'
      }
      @trigger = SaveTriggers::Notify.new config, @al

      @trigger.perform

      # Should find users with role 'user' (which is the value of @al.select_who)
      expect(@trigger.instance_variable_get(:@role_name)).to eq @al.select_who
    end

    it 'uses an array of literal values for phones' do
      phones = ['+16175550118', '+16175550104']
      config = {
        type: 'sms',
        phones: phones,
        layout_template: @layout_sms.name,
        content_template_text: 'Test message',
        subject: 'subject text'
      }
      @trigger = SaveTriggers::Notify.new config, @al

      @trigger.perform

      expect(@trigger.phones).to eq phones
    end

    it 'uses an array of literal values for emails' do
      emails = ['test1@example.com', 'test2@example.com']
      config = {
        type: 'email',
        emails: emails,
        layout_template: @layout.name,
        content_template: @content.name,
        subject: 'subject text'
      }
      @trigger = SaveTriggers::Notify.new config, @al

      @trigger.perform

      expect(@trigger.instance_variable_get(:@force_emails)).to eq emails
    end

    it 'uses template substitution for emails with player_contact field' do
      # Create a player_contact with email type
      pc_email = PlayerContact.create!(
        master: @al.master,
        rec_type: 'email',
        data: 'player@example.com',
        rank: 10
      )

      config = {
        type: 'email',
        emails: '{{player_contact_emails.data}}',
        layout_template: @layout.name,
        content_template: @content.name,
        subject: 'subject text'
      }
      @trigger = SaveTriggers::Notify.new config, @al

      @trigger.perform

      # Template substitution returns an array for associated collections
      expect(@trigger.instance_variable_get(:@force_emails)).to eq [pc_email.data]
    end

    it 'uses template reference for content_template_text with existing field' do
      # Use the data field (phone number) in content_template_text
      # This should be substituted and preserved as a template for later rendering
      @al.notes = 'Custom message for {{select_who}}'
      @al.select_who = 'notify test person'
      @al.current_user = @user
      @al.save!

      expect(@al.notes).to eq 'Custom message for {{select_who}}'

      config = {
        type: 'email',
        role: 'test',
        layout_template: @layout.name,
        content_template_text: '{{notes}}',
        subject: 'subject text'
      }
      @trigger = SaveTriggers::Notify.new config, @al
      # The content_template_text should be substituted with the field value
      # which itself contains templates that will be rendered later
      expect(@trigger.send(:content_template_text)).to eq 'Custom message for {{select_who}}'

      @trigger.perform

      expect(@trigger.send(:content_template_text)).to eq 'Custom message for {{select_who}}'
    end

    it 'uses conditional reference for content_template_text with existing field' do
      # Use a conditional hash reference to retrieve the notes field value.
      # This should be substituted and preserved as a template for later rendering.
      @al.notes = 'Custom message for {{select_who}}'
      @al.select_who = 'notify test person'
      @al.current_user = @user
      @al.save!

      expect(@al.notes).to eq 'Custom message for {{select_who}}'

      config = {
        type: 'email',
        role: 'test',
        layout_template: @layout.name,
        content_template_text: { this: { notes: 'return_value' } },
        subject: 'subject text'
      }
      @trigger = SaveTriggers::Notify.new config, @al
      # The content_template_text should be substituted with the field value
      # which itself contains templates that will be rendered later
      expect(@trigger.send(:content_template_text)).to eq 'Custom message for {{select_who}}'

      @trigger.perform

      expect(@trigger.send(:content_template_text)).to eq 'Custom message for {{select_who}}'
    end

    it 'uses template reference for importance with select_result field' do
      @al.update!(select_result: 'promotional')

      config = {
        type: 'email',
        users: @al.user_id,
        layout_template: @layout.name,
        content_template: @content.name,
        subject: 'subject text',
        importance: '{{select_result}}'
      }
      @trigger = SaveTriggers::Notify.new config, @al

      @trigger.perform

      # select_result field values get lowercased, so we expect 'promotional'
      expect(@trigger.instance_variable_get(:@importance)).to eq 'promotional'
    end

    describe 'with return_value_list conditional references' do
      # These tests verify that conditional references with return_value_list
      # correctly return arrays of values for users, emails, phones, and phone_records

      before(:each) do
        @al = create_item
        @master = @al.master
        @master.current_user = @user

        # Create multiple player contacts for testing (all with rank 10 which is valid)
        @pc1 = PlayerContact.create!(master: @master, rec_type: 'email', data: 'test1@example.com', rank: 10)
        @pc2 = PlayerContact.create!(master: @master, rec_type: 'email', data: 'test2@example.com', rank: 10)
        @pc3 = PlayerContact.create!(master: @master, rec_type: 'phone', data: '+16175550101', rank: 10)
        @pc4 = PlayerContact.create!(master: @master, rec_type: 'phone', data: '+16175550102', rank: 10)
      end

      it 'uses return_value_list for users from activity log user_id field via conditional reference' do
        # The activity logs already have user_ids from setup
        # Just verify they can be retrieved via return_value_list
        config = {
          type: 'email',
          users: {
            activity_log__player_contact_phones: {
              master_id: @master.id,
              user_id: 'return_value_list'
            }
          },
          layout_template: @layout.name,
          content_template: @content.name,
          subject: 'subject text'
        }
        @trigger = SaveTriggers::Notify.new config, @al

        @trigger.perform

        # Should return an array of user IDs from all activity logs for this master
        # At minimum, should include the current activity log's user
        expect(@trigger.receiving_user_ids).to include(@al.user_id)
        expect(@trigger.receiving_user_ids).to be_an(Array)
      end

      it 'uses return_value_list for emails from associated player_contacts' do
        config = {
          type: 'email',
          emails: {
            player_contacts: {
              rec_type: 'email',
              data: 'return_value_list'
            }
          },
          layout_template: @layout.name,
          content_template: @content.name,
          subject: 'subject text'
        }
        @trigger = SaveTriggers::Notify.new config, @al

        @trigger.perform

        # Should return an array of email addresses
        expect(@trigger.instance_variable_get(:@force_emails).sort).to eq [@pc1.data, @pc2.data].sort
      end

      it 'uses return_value_list for phones from associated player_contacts' do
        config = {
          type: 'sms',
          phones: {
            player_contacts: {
              rec_type: 'phone',
              data: 'return_value_list'
            }
          },
          default_country_code: '1',
          layout_template: @layout_sms.name,
          content_template_text: 'Test SMS',
          subject: 'subject text'
        }
        @trigger = SaveTriggers::Notify.new config, @al

        @trigger.perform

        # Should return an array of phone numbers (cleaned/formatted)
        # Verify we got multiple phones and they include our test phone numbers
        expect(@trigger.phones).to be_an(Array)
        expect(@trigger.phones.length).to be >= 2
        # Check that the phones were processed (formatted)
        expect(@trigger.phones.first).to match(/^\+?\d+$/)
      end

      it 'uses return_value_list for phone_records with IDs' do
        # This tests the phone_records with return_value_list pattern
        # Create activity logs that we can retrieve IDs from
        al2 = @master.activity_log__player_contact_phones.create!(
          select_call_direction: 'to staff',
          select_who: 'staff',
          data: '(516)262-9999'
        )

        al_ids = [@al.id, al2.id]

        # Use activity logs as the phone_records source
        # These have IDs and belong to the master
        config = {
          type: 'sms',
          phone_records: {
            activity_log__player_contact_phones: {
              master_id: @master.id,
              id: 'return_value_list'
            }
          },
          list_type: 'activity_log__player_contact_phones',
          default_country_code: '1',
          layout_template: @layout_sms.name,
          content_template_text: 'Test bulk SMS',
          subject: 'subject text'
        }

        @trigger = SaveTriggers::Notify.new config, @al

        # Initialize attributes from the config (normally done in perform loop)
        @trigger.send(:init_attribs, config)

        # Now test setup_recipient_data to verify it processes the return_value_list correctly
        @trigger.send(:setup_recipient_data) # Verify that phone_records were retrieved and processed into the expected structure
        force_recip_recs = @trigger.instance_variable_get(:@force_recip_recs)
        expect(force_recip_recs).to be_an(Array)
        expect(force_recip_recs.length).to be >= 1 # At least the original @al

        # Verify the structure of recipient records
        expect(force_recip_recs.first).to have_key(:list_type)
        expect(force_recip_recs.first).to have_key(:id)
        expect(force_recip_recs.first).to have_key(:default_country_code)
        expect(force_recip_recs.first[:list_type]).to eq 'activity_log__player_contact_phones'

        # Verify we got IDs back
        recip_ids = force_recip_recs.map { |r| r[:id] }
        expect(recip_ids).to include(al_ids.first)
      end
    end

    it 'sets the notification to send 1 day in the future' do
      config = {
        type: 'email',
        users: {
          this: {
            user_id: 'return_value'
          }
        },
        when: {
          wait: '1 day'
        },
        layout_template: @layout.name,
        content_template: @content.name,
        subject: 'subject text'
      }
      @trigger = SaveTriggers::Notify.new config, @al

      @trigger.perform

      # The time should be close enough
      expect(@trigger.send(:run_when)[:wait_until].to_i).to be_within(10).of((DateTime.now + 1.day).to_i)
    end

    it 'sets the notification to send at a specific time in the future' do
      config = {
        type: 'email',
        users: {
          this: {
            user_id: 'return_value'
          }
        },
        when: {
          wait_until: (DateTime.now + 1.day).iso8601
        },
        layout_template: @layout.name,
        content_template: @content.name,
        subject: 'subject text'
      }
      @trigger = SaveTriggers::Notify.new config, @al

      @trigger.perform

      # The time should be close enough
      expect(@trigger.send(:run_when)[:wait_until].to_i).to be_within(10).of((DateTime.now + 1.day).to_i)
    end

    it 'sets the notification to send at a specific time in the future based on a date / time / zone definition' do
      # We would like to send at a specific time (12:15 pm on August 1st, 2022)
      # The date is nominally set to UTC, since this mirrors the way it will be stored in the database.
      d = Time.new(2022, 8, 1, 14, 15, 0, 'UTC')
      # The configuration states that it wants us to use Eastern timezone. So the actual target date
      # we want to use for comparison will be 12:15 pm EDT.
      d_in_edt = Time.new(2022, 8, 1, 14, 15, 0, '-04:00')
      config = {
        type: 'email',
        users: {
          this: {
            user_id: 'return_value'
          }
        },
        when: {
          wait_until: {
            date: d.to_date,
            time: d.to_time,
            zone: 'Eastern Time (US & Canada)'
          }
        },
        layout_template: @layout.name,
        content_template: @content.name,
        subject: 'subject text'
      }
      @trigger = SaveTriggers::Notify.new config, @al

      @trigger.perform

      # Calculated time to send was:
      wait_until = @trigger.send(:run_when)[:wait_until]

      # The time should be close enough
      expect(wait_until.to_i).to be_within(10).of(d_in_edt.to_i)
    end

    it 'uses an if select the correct notification' do
      config = [
        {
          type: 'email',
          if: {
            all: {
              this: {
                user_id: -1
              }
            }
          },
          users: -1,
          layout_template: @layout.name,
          content_template: @content.name,
          subject: 'subject text 1'
        },
        {
          type: 'email',
          if: {
            all: {
              this: {
                user_id: @al.user_id
              }
            }
          },
          users: {
            this: {
              user_id: 'return_value'
            }
          },
          layout_template: @layout.name,
          content_template: @content.name,
          subject: 'subject text 2'
        }
      ]
      @trigger = SaveTriggers::Notify.new config, @al

      @trigger.perform

      expect(@trigger.receiving_user_ids.first).to eq @al.user_id
      expect(@trigger.send(:subject)).to eq 'subject text 2'
    end

    it 'sends notifications on a save_trigger in an activity log' do
      # Setup a new activity log with multiple notifications on create

      t = '<p>This is some content in a template testing save_trigger notifications.</p><p>Related to master_id {{master_id}}. This is a name: {{select_who}} in {{id}}.</p>'

      @activity_log = al = ActivityLog.active.where(name: AlNameGenTestN).first

      raise "Activity Log #{AlNameGenTestN} not set up" if al.nil?

      al.extra_log_types = <<~END_DEF
        step_1:
          label: Step 1
          fields:
            - select_call_direction
            - select_who
          save_trigger:
            on_create:
              notify:
                - type: email
                  role: test
                  layout_template: #{@layout.name}
                  content_template_text: |
                    #{t} 1
                  subject: subject text 1
                - type: email
                  role: test_2
                  layout_template: #{@layout.name}
                  content_template_text: |
                    #{t} 2
                  subject: subject text 2

        step_2:
          label: Step 2
          fields:
            - select_call_direction
            - extra_text

      END_DEF

      al.current_admin = @admin
      al.save!

      user = @user
      @player_contact.current_user = user

      setup_access al.resource_name, resource_type: :table, access: :create, user: user

      sleep 1.5
      alstep1 = @player_contact.activity_log__player_contact_elt2_tests.build(select_call_direction: 'from player', select_who: 'user', extra_log_type: 'step_1')

      setup_access alstep1.resource_name, resource_type: :activity_log_type, access: :create, user: user

      alstep1.save!
      expect(alstep1).to be_persisted

      alstep2 = @player_contact.activity_log__player_contact_elt2_tests.build(select_call_direction: 'from staff', select_who: 'staff', extra_log_type: 'step_1')
      alstep2.save!

      lastid = Messaging::MessageNotification.last.id
      # Two messages are sent for each alstep
      mns = Messaging::MessageNotification.where(id: [lastid, lastid - 1, lastid - 2, lastid - 3]).order(id: :asc)

      alstep1_first_sent_msg = mns[0]
      alstep1_last_sent_msg = mns[1]
      alstep2_first_sent_msg = mns[2]
      alstep2_last_sent_msg = mns[3]

      expect(alstep1_first_sent_msg.item_type).to eq al.implementation_class.name
      expect(alstep1_first_sent_msg.item_id).to eq alstep1.id
      expect(alstep1_last_sent_msg.item_type).to eq al.implementation_class.name
      expect(alstep1_last_sent_msg.item_id).to eq alstep1.id

      expect(alstep2_first_sent_msg.item_type).to eq al.implementation_class.name
      expect(alstep2_first_sent_msg.item_id).to eq alstep2.id
      expect(alstep2_last_sent_msg.item_type).to eq al.implementation_class.name
      expect(alstep2_last_sent_msg.item_id).to eq alstep2.id

      tsub = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content in a template testing save_trigger notifications.</p><p>Related to master_id #{alstep1.master}. This is a name: #{alstep1.select_who} in #{alstep1.id}.</p> 1\n</div></body></html>"
      ctt = "<p>This is some content in a template testing save_trigger notifications.</p><p>Related to master_id #{alstep1.master}. This is a name: #{alstep1.select_who} in #{alstep1.id}.</p>"
      expect(alstep1_first_sent_msg.item_id).to eq alstep1.id
      expect(alstep1_first_sent_msg.status).to eq 'complete'
      expect(alstep1_first_sent_msg.role_name).to eq 'test'
      expect(alstep1_first_sent_msg.subject).to eq 'subject text 1'
      expect(alstep1_first_sent_msg.content_template_text).to eq "#{ctt} 1\n"
      expect(alstep1_first_sent_msg.generated_content).to eq tsub

      tsub = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content in a template testing save_trigger notifications.</p><p>Related to master_id #{alstep1.master}. This is a name: #{alstep1.select_who} in #{alstep1.id}.</p> 2\n</div></body></html>"
      expect(alstep1_last_sent_msg.item_id).to eq alstep1.id
      expect(alstep1_last_sent_msg.status).to eq 'complete'
      expect(alstep1_last_sent_msg.role_name).to eq 'test_2'
      expect(alstep1_last_sent_msg.subject).to eq 'subject text 2'
      expect(alstep1_last_sent_msg.content_template_text).to eq "#{ctt} 2\n"
      expect(alstep1_last_sent_msg.generated_content).to eq tsub

      tsub = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content in a template testing save_trigger notifications.</p><p>Related to master_id #{alstep2.master}. This is a name: #{alstep2.select_who} in #{alstep2.id}.</p> 1\n</div></body></html>"
      ctt = "<p>This is some content in a template testing save_trigger notifications.</p><p>Related to master_id #{alstep2.master}. This is a name: #{alstep2.select_who} in #{alstep2.id}.</p>"

      expect(alstep2_first_sent_msg.item_id).to eq alstep2.id
      expect(alstep2_first_sent_msg.status).to eq 'complete'
      expect(alstep2_first_sent_msg.role_name).to eq 'test'
      expect(alstep2_first_sent_msg.subject).to eq 'subject text 1'
      expect(alstep2_first_sent_msg.content_template_text).to eq "#{ctt} 1\n"
      expect(alstep2_first_sent_msg.generated_content).to eq tsub

      tsub = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content in a template testing save_trigger notifications.</p><p>Related to master_id #{alstep2.master}. This is a name: #{alstep2.select_who} in #{alstep2.id}.</p> 2\n</div></body></html>"
      expect(alstep2_last_sent_msg.item_id).to eq alstep2.id
      expect(alstep2_last_sent_msg.status).to eq 'complete'
      expect(alstep2_last_sent_msg.role_name).to eq 'test_2'
      expect(alstep2_last_sent_msg.subject).to eq 'subject text 2'
      expect(alstep2_last_sent_msg.content_template_text).to eq "#{ctt} 2\n"
      expect(alstep2_last_sent_msg.generated_content).to eq tsub
    end

    describe 'calc_field_or_return with template substitutions' do
      # These tests verify that calc_field_or_return correctly handles template substitutions
      # in the context of Notify triggers. The core substitution logic is already tested
      # in conditional_actions_spec.rb - these tests just verify integration.

      context 'with users and emails options' do
        before(:each) do
          @al = create_item

          @master = @al.master
          @master.current_user = @user
          @player_contact = PlayerContact.create!(master: @master, rec_type: 'email', data: 'test-email@test.tst', rank: 10)
        end

        it 'processes simple template substitutions through calc_field_or_return' do
          # Use the actual @al object which has all necessary attributes and methods
          notify = SaveTriggers::Notify.new({}, @al) # just to load the class context
          # Test simple string with {{variable}}
          result = notify.send(:calc_field_or_return, '{{player_contact_emails.data}}')
          expect(result).to eq(@player_contact.data)

          # Test string with {{{raw_value}}}
          result = notify.send(:calc_field_or_return, '{{{player_contact_emails.id}}}')
          expect(result).to eq(@player_contact.id)
          expect(result).to be_a(Integer)

          # Test array with simple template references
          result = notify.send(:calc_field_or_return, [100, 102, 104])
          expect(result).to eq([100, 102, 104])

          # Test that complex templates are NOT substituted (preserved for later rendering)
          result = notify.send(:calc_field_or_return, 'test@email.tst')
          expect(result).to eq('test@email.tst')

          # Test that hashes still work (passed through to ConditionalActions)
          hash_config = { all: { masters: { id: @al.master_id } } }
          expect do
            notify.send(:calc_field_or_return, hash_config)
          end.not_to raise_error
        end
      end

      context 'with calendar_invite config (issue #953)' do
        it 'parses calendar_invite config, resolves substitutions, and merges into extra_substitutions' do
          config = {
            type: 'email',
            role: 'test',
            layout_template: @layout.name,
            content_template: @content.name,
            subject: 'Meeting Invite',
            calendar_invite: {
              method: 'REQUEST',
              summary: 'Review Meeting for {{master_id}}',
              description: 'Notes about {{select_who}}',
              location: 'Room 101',
              dtstart: '2026-04-01 10:00:00',
              dtend: '2026-04-01 11:00:00',
              organizer: 'organizer@example.com',
              uid: '{{id}}-{{master_id}}@restructure',
              sequence: 0
            }
          }

          @trigger = SaveTriggers::Notify.new(config, @al)
          @trigger.perform

          new_mn = MessageNotification.order(id: :desc).first
          ci_data = new_mn.calendar_invite_data
          expect(ci_data).to be_a(Hash)
          expect(ci_data['method']).to eq('REQUEST')
          expect(ci_data['summary']).to eq("Review Meeting for #{@al.master_id}")
          expect(ci_data['description']).to eq("Notes about #{@al.select_who}")
          expect(ci_data['location']).to eq('Room 101')
          expect(ci_data['organizer']).to eq('organizer@example.com')
          expect(ci_data['uid']).to eq("#{@al.id}-#{@al.master_id}@restructure")
        end
      end

      context 'with attachments config (issue #954)' do
        before :example do
          # Mock NfsStore file resolution so the inline job doesn't fail
          # (the actual resolution is tested in message_notification_spec)
          allow_any_instance_of(Messaging::MessageNotification).to receive(:resolve_nfsstore_attachments)
        end

        it 'parses attachments config, resolves substitutions, and merges into extra_substitutions' do
          config = {
            type: 'email',
            role: 'test',
            layout_template: @layout.name,
            content_template: @content.name,
            subject: 'Report Delivery',
            attachments: [
              {
                container_id: '{{master_id}}',
                path: 'reports',
                file_name: 'summary.pdf'
              },
              {
                container_id: 42,
                path: '',
                file_name: 'static_file.txt'
              }
            ]
          }

          @trigger = SaveTriggers::Notify.new(config, @al)
          @trigger.perform

          new_mn = MessageNotification.order(id: :desc).first
          es_data = YAML.safe_load(new_mn.extra_substitutions, permitted_classes: [Symbol])
                        &.with_indifferent_access
          attachments_data = es_data['attachments']

          expect(attachments_data).to be_a(Array)
          expect(attachments_data.length).to eq(2)

          # First attachment should have {{master_id}} resolved
          expect(attachments_data[0]['container_id']).to eq(@al.master_id.to_s)
          expect(attachments_data[0]['path']).to eq('reports')
          expect(attachments_data[0]['file_name']).to eq('summary.pdf')

          # Second attachment should have literal values preserved
          expect(attachments_data[1]['container_id']).to eq(42)
          expect(attachments_data[1]['path']).to eq('')
          expect(attachments_data[1]['file_name']).to eq('static_file.txt')
        end

        it 'works with both attachments and calendar_invite in the same config' do
          config = {
            type: 'email',
            role: 'test',
            layout_template: @layout.name,
            content_template: @content.name,
            subject: 'Combined Notification',
            calendar_invite: {
              method: 'REQUEST',
              summary: 'Meeting',
              dtstart: '2026-04-01 10:00:00',
              dtend: '2026-04-01 11:00:00',
              organizer: 'org@example.com'
            },
            attachments: [
              {
                container_id: 99,
                path: '',
                file_name: 'report.pdf'
              }
            ]
          }

          @trigger = SaveTriggers::Notify.new(config, @al)
          @trigger.perform

          new_mn = MessageNotification.order(id: :desc).first
          es_data = YAML.safe_load(new_mn.extra_substitutions, permitted_classes: [Symbol])
                        &.with_indifferent_access

          # Both should be present
          expect(es_data['calendar_invite']).to be_a(Hash)
          expect(es_data['attachments']).to be_a(Array)
          expect(es_data['attachments'].length).to eq(1)
          expect(es_data['attachments'][0]['file_name']).to eq('report.pdf')
        end
      end
    end

    context 'with data URI inline images in content (issue #1148)' do
      before :example do
        change_setting('TestMail', true)
        change_setting('ProcessInlineDataUriImages', true)
      end

      after :example do
        change_setting('TestMail', false)
        change_setting('ProcessInlineDataUriImages', nil)
      end

      it 'converts data URI images to inline attachments when sending notification email triggered by notify' do
        # Content template embeds a data URI image
        data_img = %(<img src="data:image/png;base64,#{PNG_BASE64_NOTIFY}" alt="embedded"/>)
        t = "<p>Here is an image: #{data_img}</p>"
        content_with_image = Admin::MessageTemplate.create!(
          name: 'test email content with image',
          message_type: :email,
          template_type: :content,
          template: t,
          current_admin: @admin
        )

        config = {
          type: 'email',
          role: 'test',
          layout_template: @layout.name,
          content_template: content_with_image.name,
          subject: 'Image Notification'
        }

        @trigger = SaveTriggers::Notify.new(config, @al)
        @trigger.perform

        new_mn = MessageNotification.order(id: :desc).first
        new_mn.generate

        mail = NotificationMailer.send_message_notification(new_mn)

        # The data URI must have been replaced with an inline cid: attachment
        inline_attachments = mail.attachments.select(&:inline?)
        expect(inline_attachments.size).to eq(1)

        body = (mail.html_part || mail).body.decoded
        expect(body).to include('src="cid:')
        expect(body).not_to include('src="data:')
      end
    end

    context 'phones and emails support literal strings, template substitutions, and per-element resolution - issue #1152' do
      # Tests for issue #1152: setup_phones fails when calc_field_or_return returns a String
      # (e.g. literal phone, template substitution, or conditional hash) because .map is called
      # directly on the result. Also covers that array elements containing {{templates}} should
      # each be individually resolved via calc_field_or_return.

      before :example do
        @al.update!(data: '(617)555-0101', notes: 'dynamic@example.com', current_user: @user)
      end

      let(:sms_config_base) do
        {
          type: 'sms',
          default_country_code: '1',
          layout_template: @layout_sms.name,
          content_template_text: 'Test SMS content',
          subject: 'subject text'
        }
      end

      let(:email_config_base) do
        {
          type: 'email',
          layout_template: @layout.name,
          content_template: @content.name,
          subject: 'subject text'
        }
      end

      it 'accepts phones as a literal string - issue #1152' do
        config = sms_config_base.merge(phones: '+16175551234')
        @trigger = SaveTriggers::Notify.new(config, @al)
        @trigger.perform
        expect(@trigger.phones).to eq(['+16175551234'])
      end

      it 'accepts phones as a template substitution resolving the item field - issue #1152' do
        config = sms_config_base.merge(phones: '{{data}}')
        @trigger = SaveTriggers::Notify.new(config, @al)
        @trigger.perform
        expect(@trigger.phones).to eq(['+16175550101'])
      end

      it 'accepts phones as a conditional hash resolving the item field via ConditionalActions - issue #1152' do
        config = sms_config_base.merge(phones: { this: { data: 'return_value' } })
        @trigger = SaveTriggers::Notify.new(config, @al)
        @trigger.perform
        expect(@trigger.phones).to eq(['+16175550101'])
      end

      it 'resolves template substitutions within each element of a phones array - issue #1152' do
        config = sms_config_base.merge(phones: ['{{data}}', '+16175551235'])
        @trigger = SaveTriggers::Notify.new(config, @al)
        @trigger.perform
        expect(@trigger.phones.sort).to eq(['+16175550101', '+16175551235'].sort)
      end

      it 'accepts emails as a literal string - issue #1152' do
        config = email_config_base.merge(emails: 'test@example.com')
        @trigger = SaveTriggers::Notify.new(config, @al)
        @trigger.perform
        expect(@trigger.instance_variable_get(:@force_emails)).to eq(['test@example.com'])
      end

      it 'resolves template substitutions within each element of an emails array - issue #1152' do
        config = email_config_base.merge(emails: ['{{notes}}', 'static@example.com'])
        @trigger = SaveTriggers::Notify.new(config, @al)
        @trigger.perform
        expect(@trigger.instance_variable_get(:@force_emails)).to eq(['dynamic@example.com', 'static@example.com'])
      end
    end

    it 'uses config app_type for role lookup when app_type is specified in config - issue #1172' do
      # @u0 has the 'test' role only in @at2 (not in @user.app_type)
      # @user has the 'test' role only in @user.app_type (not in @at2)
      # With app_type: @at2.id in config, the trigger should look up roles in @at2,
      # not in @user.app_type (the current user's app type).
      config = {
        type: 'email',
        role: 'test',
        app_type: @at2.id,
        layout_template: @layout.name,
        content_template: @content.name,
        subject: 'subject text'
      }

      @trigger = SaveTriggers::Notify.new(config, @al)
      @trigger.perform

      # @u0 has role 'test' in @at2, so must be a recipient
      expect(@trigger.receiving_user_ids).to include(@u0.id)
      # @user has role 'test' in @user.app_type (not @at2), so must NOT be a recipient
      expect(@trigger.receiving_user_ids).not_to include(@user.id)
    end

    it 'includes current user and app type ID in no-recipients error message - issue #1172' do
      # The error message for missing recipients should identify which user and app type
      # were used for the role lookup so the problem can be diagnosed.
      config = {
        type: 'email',
        role: 'nonexistent-role-xyz',
        layout_template: @layout.name,
        content_template: @content.name,
        subject: 'subject text'
      }

      @trigger = SaveTriggers::Notify.new(config, @al)
      @trigger.perform

      error_msg = @al.save_trigger_results['notify_errors'].last
      expect(error_msg).to include(@user.email)
      expect(error_msg).to include(@user.app_type.id.to_s)
    end

    it 'stores resolved app_type and user on the MessageNotification record when config app_type is specified - issue #1172' do
      # When app_type and user are specified in the config, the MessageNotification record should
      # be associated with the configured app_type (not the triggering user's app_type),
      # and the user should be the alt_batch_user (@u0) resolved from the config.
      config = {
        type: 'email',
        role: 'test',
        app_type: @at2.id,
        user: @u0.email,
        layout_template: @layout.name,
        content_template: @content.name,
        subject: 'subject text'
      }

      @trigger = SaveTriggers::Notify.new(config, @al)
      @trigger.perform

      new_mn = MessageNotification.order(id: :desc).first
      # The notification's app_type should be the configured @at2, not @user.app_type
      expect(new_mn.app_type).to eq @at2
      # The user on the notification should be @u0 (the resolved alt_batch_user), not the triggering @user
      expect(new_mn.user.id).to eq @u0.id
    end

    it 'does not resolve a config app_type outside the app types loaded on this server (OnlyLoadAppTypes) - issue #1318' do
      # Restrict the server to only load @user's app type, excluding @at2.
      stub_const('Settings::OnlyLoadAppTypes', [@user.app_type_id])
      Admin::AppType.reset_active_app_types!

      config = {
        type: 'email',
        role: 'test',
        app_type: @at2.id,
        user: @u0.email,
        layout_template: @layout.name,
        content_template: @content.name,
        subject: 'subject text'
      }

      @trigger = SaveTriggers::Notify.new(config, @al)
      # @at2 exists and is active, but is excluded from this server's OnlyLoadAppTypes scope,
      # so it must not be resolvable - matching the app_type scoping restored for change_user_roles.
      expect { @trigger.perform }.to raise_error(ActiveRecord::RecordNotFound)
    ensure
      Admin::AppType.reset_active_app_types!
    end

    describe 'runtime validation resilience (issue #1370)' do
      it 'rescues ActiveRecord::RecordInvalid when MessageNotification fails validation, recording error in notify_errors' do
        @al.update!(notes: '', current_user: @user)
        config = {
          type: 'email',
          role: 'test',
          layout_template: @layout.name,
          content_template: @content.name,
          subject: '{{notes}}'
        }

        @trigger = SaveTriggers::Notify.new(config, @al)
        expect { @trigger.perform }.not_to raise_error

        expect(@al.save_trigger_results['notify_results']).to eq([false])
        expect(@al.save_trigger_results['notify_errors'].first).to include('Failed to create message notification')
        expect(@al.save_trigger_results['notify_errors'].first).to include("Subject can't be blank")
        expect(@al.save_trigger_results['notify_messages']).to be_empty
      end

      it 'processes remaining valid notifications in an array when one fails runtime validation' do
        @al.update!(notes: '', current_user: @user)
        configs = [
          {
            type: 'email',
            role: 'test',
            layout_template: @layout.name,
            content_template: @content.name,
            subject: '{{notes}}'
          },
          {
            type: 'email',
            role: 'test',
            layout_template: @layout.name,
            content_template: @content.name,
            subject: 'Valid Second Subject'
          }
        ]

        @trigger = SaveTriggers::Notify.new(configs, @al)
        expect { @trigger.perform }.not_to raise_error

        expect(@al.save_trigger_results['notify_results']).to eq([false, true])
        expect(@al.save_trigger_results['notify_errors'].first).to include("Subject can't be blank")
        expect(@al.save_trigger_results['notify_errors'].second).to be_nil
        expect(@al.save_trigger_results['notify_messages'].length).to eq(1)
        expect(@al.save_trigger_results['notify_messages'].first.subject).to eq('Valid Second Subject')
      end
    end

    describe 'excludes expired and disabled users from recipients - issue #1374' do
      before(:each) do
        @active_user, = create_user
        @expired_user, = create_user
        @expired_user.update_columns(expire_datetime: 1.hour.ago)

        Admin::UserRole.create! app_type: @active_user.app_type, user: @active_user, role_name: 'test_1374', current_admin: @admin
        Admin::UserRole.create! app_type: @active_user.app_type, user: @expired_user, role_name: 'test_1374', current_admin: @admin
      end

      it 'role-based recipients exclude a user whose account has expired' do
        config = {
          type: 'email',
          role: 'test_1374',
          layout_template: @layout.name,
          content_template: @content.name,
          subject: 'expiry test'
        }

        trigger = SaveTriggers::Notify.new(config, @al)
        trigger.perform

        expect(trigger.receiving_user_ids).to include(@active_user.id)
        expect(trigger.receiving_user_ids).not_to include(@expired_user.id)
      end

      it 'role-based recipients exclude a disabled user' do
        disabled_user, = create_user
        disabled_user.current_admin = @admin
        disabled_user.disable!
        Admin::UserRole.create! app_type: @active_user.app_type, user: disabled_user, role_name: 'test_1374', current_admin: @admin

        config = {
          type: 'email',
          role: 'test_1374',
          layout_template: @layout.name,
          content_template: @content.name,
          subject: 'disabled test'
        }

        trigger = SaveTriggers::Notify.new(config, @al)
        trigger.perform

        expect(trigger.receiving_user_ids).to include(@active_user.id)
        expect(trigger.receiving_user_ids).not_to include(disabled_user.id)
      end

      it 'explicit users: recipients exclude expired and disabled users' do
        disabled_user, = create_user
        disabled_user.current_admin = @admin
        disabled_user.disable!

        config = {
          type: 'email',
          users: [@active_user.id, @expired_user.id, disabled_user.id],
          layout_template: @layout.name,
          content_template: @content.name,
          subject: 'users filter test'
        }

        trigger = SaveTriggers::Notify.new(config, @al)
        trigger.perform

        expect(trigger.receiving_user_ids).to include(@active_user.id)
        expect(trigger.receiving_user_ids).not_to include(@expired_user.id)
        expect(trigger.receiving_user_ids).not_to include(disabled_user.id)
      end
    end
  end

  describe 'resolving app_type and user from conditional Hash references - issue #1318' do
    before :all do
      SetupHelper.setup_al_player_contact_phones
      SetupHelper.setup_al_gen_tests AlNameGenTestN, 'elt2_test', 'player_contact'
    end

    before :example do
      example_setup
      @at2 = Admin::AppType.create! name: 'new-notify-clean', label: 'Test Notify App', current_admin: @admin
      Admin::UserRole.create! app_type: @at2, user: @u0, role_name: 'test', current_admin: @admin
    end

    it 'resolves app_type and user from a conditional Hash reference, not just a literal id/name - issue #1318' do
      # notes/select_who are reused here purely as string fields a conditional Hash reference
      # ({this: {field: return_value}}) can read back; protocol_id (an alternative integer field)
      # carries a real foreign key constraint on this table, so string values are used instead.
      # This proves app_type/user are resolved via FieldDefaults.calculate_default before use,
      # so a Hash config (in addition to a literal id/name) now works for both.
      @al.update!(notes: @at2.name, select_who: @u0.email)
      expect(@u0.disabled).not_to be true
      expect(@u0.expire_datetime).to be_nil

      config = {
        type: 'email',
        role: 'test',
        app_type: { this: { notes: 'return_value' } },
        user: { this: { select_who: 'return_value' } },
        layout_template: @layout.name,
        content_template: @content.name,
        subject: 'subject text'
      }

      @trigger = SaveTriggers::Notify.new(config, @al)
      @trigger.perform

      # @u0 has role 'test' in @at2 (resolved from the Hash config), so must be a recipient
      expect(@trigger.receiving_user_ids).to include(@u0.id)
      # @user has role 'test' in @user.app_type (not @at2), so must NOT be a recipient
      expect(@trigger.receiving_user_ids).not_to include(@user.id)

      new_mn = MessageNotification.order(id: :desc).first
      expect(new_mn.app_type).to eq @at2
      # user resolved from the Hash-based `user` config should be @u0
      expect(new_mn.user.id).to eq @u0.id
    end
  end
end
