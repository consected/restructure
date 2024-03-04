# frozen_string_literal: true

require 'rails_helper'

AlNameGenTestN = 'Gen Test ELT 2'

RSpec.describe SaveTriggers::Notify, type: :model do
  include ModelSupport
  include ActivityLogSupport
  include AwsApiStubs

  before :example do
    SetupHelper.setup_al_player_contact_phones
    SetupHelper.setup_al_gen_tests AlNameGenTestN, 'elt2_test', 'player_contact'
    ud, = create_user
    ud.disable!
    u0, = create_user
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

    at2 = Admin::AppType.create! name: 'new-notify', label: 'Test Notify App', current_admin: @admin
    Admin::UserRole.create! app_type: at2, user: u0, role_name: 'test', current_admin: @admin

    # The number of roles is one more than we added due to automatic setup of a template@template item
    expect(Admin::UserRole.joins(:user).where(role_name: 'test', app_type: u1.app_type).where('users.disabled is null or users.disabled = false').count).to eq 4

    @non_template_user_ids = [u1.id, @user.id, ud.id]
    @role_user_ids = @non_template_user_ids + [User.template_user.id]

    setup_stub(:sns_send_sms)
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

    @al.extra_log_type_config.clean_references_def
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
    expect(@trigger.send(:run_when)[:wait_until].to_i / 10).to eq((DateTime.now + 1.day).to_i / 10) || eq(((DateTime.now + 1.day).to_i - 1) / 10)
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
    expect(@trigger.send(:run_when)[:wait_until].to_i / 10).to eq((DateTime.now + 1.day).to_i / 10) || eq(((DateTime.now + 1.day).to_i - 1) / 10)
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
    expect(wait_until.to_i / 10).to eq(d_in_edt.to_i / 10) || eq((d_in_edt.to_i - 1) / 10)
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
    expect(alstep1_first_sent_msg.item_id).to eq alstep1.id
    expect(alstep1_first_sent_msg.status).to eq 'complete'
    expect(alstep1_first_sent_msg.role_name).to eq 'test'
    expect(alstep1_first_sent_msg.subject).to eq 'subject text 1'
    expect(alstep1_first_sent_msg.content_template_text).to eq "#{t} 1\n"
    expect(alstep1_first_sent_msg.generated_content).to eq tsub

    tsub = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content in a template testing save_trigger notifications.</p><p>Related to master_id #{alstep1.master}. This is a name: #{alstep1.select_who} in #{alstep1.id}.</p> 2\n</div></body></html>"
    expect(alstep1_last_sent_msg.item_id).to eq alstep1.id
    expect(alstep1_last_sent_msg.status).to eq 'complete'
    expect(alstep1_last_sent_msg.role_name).to eq 'test_2'
    expect(alstep1_last_sent_msg.subject).to eq 'subject text 2'
    expect(alstep1_last_sent_msg.content_template_text).to eq "#{t} 2\n"
    expect(alstep1_last_sent_msg.generated_content).to eq tsub

    tsub = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content in a template testing save_trigger notifications.</p><p>Related to master_id #{alstep2.master}. This is a name: #{alstep2.select_who} in #{alstep2.id}.</p> 1\n</div></body></html>"
    expect(alstep2_first_sent_msg.item_id).to eq alstep2.id
    expect(alstep2_first_sent_msg.status).to eq 'complete'
    expect(alstep2_first_sent_msg.role_name).to eq 'test'
    expect(alstep2_first_sent_msg.subject).to eq 'subject text 1'
    expect(alstep2_first_sent_msg.content_template_text).to eq "#{t} 1\n"
    expect(alstep2_first_sent_msg.generated_content).to eq tsub

    tsub = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content in a template testing save_trigger notifications.</p><p>Related to master_id #{alstep2.master}. This is a name: #{alstep2.select_who} in #{alstep2.id}.</p> 2\n</div></body></html>"
    expect(alstep2_last_sent_msg.item_id).to eq alstep2.id
    expect(alstep2_last_sent_msg.status).to eq 'complete'
    expect(alstep2_last_sent_msg.role_name).to eq 'test_2'
    expect(alstep2_last_sent_msg.subject).to eq 'subject text 2'
    expect(alstep2_last_sent_msg.content_template_text).to eq "#{t} 2\n"
    expect(alstep2_last_sent_msg.generated_content).to eq tsub
  end
end
