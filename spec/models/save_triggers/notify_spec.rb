require 'rails_helper'

RSpec.describe SaveTriggers::Notify, type: :model do

  include ModelSupport
  include ActivityLogSupport

  before :all do
    ud, _ = create_user
    ud.disable!
    u0, _ = create_user
    u1, _ = create_user
    create_user
    let_user_create :player_contacts
    create_master
    @al = create_item

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

    at2 = Admin::AppType.create! name: 'new-notify', label:'Test Notify App', current_admin: @admin
    Admin::UserRole.create! app_type: at2, user: u0, role_name: 'test', current_admin: @admin

    expect(Admin::UserRole.joins(:user).where(role_name: 'test', app_type: u1.app_type).where("users.disabled is null or users.disabled = false").count).to eq 3

    @role_user_ids = [u1.id, @user.id, ud.id]

  end



  it "generates a message notification and job" do
    config = {
      type: "email",
      role: "test",
      layout_template: @layout.name,
      content_template: @content.name,
      subject: "subject text"
    }

    # Check that we only get users that are enabled for the role in this app type
    expect(Admin::UserRole.joins(:user).where(role_name: 'test', app_type: @user.app_type).where("users.disabled is null or users.disabled = false").count).to eq 3

    @trigger = SaveTriggers::Notify.new(config, @al)

    last_mn = MessageNotification.order(id: :desc).first
    # last_dj = Delayed::Job.order(id: :desc).first

    @trigger.perform

    expect(@trigger.receiving_user_ids.sort).to eq @role_user_ids.sort

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

  it "generates a message notification with text template and job" do
    t = '<p>This is some content in a text template.</p><p>Related to master_id {{master_id}}. This is a name: {{select_who}}.</p>'
    config = {
      type: "email",
      role: "test",
      layout_template: @layout.name,
      content_template_text: t,
      subject: "subject text"
    }

    # Check that we only get users that are enabled for the role in this app type
    expect(Admin::UserRole.joins(:user).where(role_name: 'test', app_type: @user.app_type).where("users.disabled is null or users.disabled = false").count).to eq 3

    @trigger = SaveTriggers::Notify.new(config, @al)

    last_mn = MessageNotification.order(id: :desc).first
    # last_dj = Delayed::Job.order(id: :desc).first

    @trigger.perform

    expect(@trigger.receiving_user_ids.sort).to eq @role_user_ids.sort

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

  it "generates an sms notification with phone numbers" do

    phones = ['(617)794-2330', '+16177942331', '6177942332', '+44(020) 671 2532']
    clean_phones = ['+16177942330', '+16177942331', '+16177942332', '+440206712532']

    t = 'This is some content in a text template.</p><p>Related to master_id {{master_id}}. This is a name: {{select_who}}'
    config = {
      type: "sms",
      phones: phones,
      default_country_code: '1',
      layout_template: @layout_sms.name,
      content_template_text: t,
      subject: "subject text"
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

  it "uses a conditional field reference to get the users for a notification" do
    config = {
      type: "email",
      users: {
        this: {
          user_id: 'return_value'
        }
      } ,
      layout_template: @layout.name,
      content_template: @content.name,
      subject: "subject text"
    }
    @trigger = SaveTriggers::Notify.new config, @al

    @trigger.perform

    expect(@trigger.receiving_user_ids.first).to eq @al.user_id

  end

  it "sets the notification to send 1 day in the future" do
    config = {
      type: "email",
      users: {
        this: {
          user_id: 'return_value'
        }
      } ,
      when: {
        wait: '1 day'
      },
      layout_template: @layout.name,
      content_template: @content.name,
      subject: "subject text"
    }
    @trigger = SaveTriggers::Notify.new config, @al

    @trigger.perform

    # The time should be close enough
    expect(@trigger.when[:wait_until].to_i/10).to eq((DateTime.now + 1.day).to_i/10) || eq(((DateTime.now + 1.day).to_i - 1)/10)

  end

  it "sets the notification to send at a specific time in the future" do
    config = {
      type: "email",
      users: {
        this: {
          user_id: 'return_value'
        }
      } ,
      when: {
        wait_until: (DateTime.now + 1.day).iso8601
      },
      layout_template: @layout.name,
      content_template: @content.name,
      subject: "subject text"
    }
    @trigger = SaveTriggers::Notify.new config, @al

    @trigger.perform

    # The time should be close enough
    expect(@trigger.when[:wait_until].to_i/10).to eq((DateTime.now + 1.day).to_i/10) || eq(((DateTime.now + 1.day).to_i - 1)/10)

  end

  it "sets the notification to send at a specific time in the future based on a date / time / zone definition" do

    d = (DateTime.now + 1.day)
    config = {
      type: "email",
      users: {
        this: {
          user_id: 'return_value'
        }
      } ,
      when: {
        wait_until: {
          date: d.to_date,
          time: d.to_time,
          zone: 'Eastern Time (US & Canada)'
        }
      },
      layout_template: @layout.name,
      content_template: @content.name,
      subject: "subject text"
    }
    @trigger = SaveTriggers::Notify.new config, @al

    @trigger.perform

    # The time should be close enough
    expect(@trigger.when[:wait_until].to_i/10).to eq(d.to_i/10) || eq((d.to_i - 1)/10)

  end

  it "uses an if select the correct notification" do
    config = [
      {
        type: "email",
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
          subject: "subject text 1"
        },
        {
          type: "email",
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
          } ,
          layout_template: @layout.name,
          content_template: @content.name,
          subject: "subject text 2"
        }
    ]
    @trigger = SaveTriggers::Notify.new config, @al

    @trigger.perform

    expect(@trigger.receiving_user_ids.first).to eq @al.user_id
    expect(@trigger.subject).to eq 'subject text 2'

  end

end
