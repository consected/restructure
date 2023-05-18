# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::MessageTemplate, type: :model do
  include MasterSupport
  include ModelSupport
  include PlayerInfoSupport
  include ReportSupport
  include ItemFlagSupport

  before :example do
    seed_database # to ensure embedded reports work
    create_admin
    create_user
    create_master
    l = Admin::MessageTemplate.last.id
    Admin::MessageTemplate.where(name: 'test email layout').update_all(name: "test old layout #{l}")
    Admin::MessageTemplate.where(name: 'test email content').update_all(name: "test old content #{l}")
    create_items
  end

  it 'generates a message' do
    t = '<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div>{{main_content}}</div></body></html>'
    layout = Admin::MessageTemplate.create! name: 'test email layout', message_type: :email, template_type: :layout,
                                            template: t, current_admin: @admin

    t = '<p>This is some content.</p><p>Related to master_id {{master_id}}. This is a name: {{name}}.</p>'
    Admin::MessageTemplate.create! name: 'test email content', message_type: :email, template_type: :content,
                                   template: t, current_admin: @admin

    res = layout.generate content_template_name: 'test email content',
                          data: { master_id: @master.id, 'name' => 'test name' }
    expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content.</p><p>Related to master_id #{@master.id}. This is a name: Test Name.</p></div></body></html>"

    expect(res).to eq expected_text
  end

  it 'generates a message with markdown content' do
    t = '<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div>{{main_content}}</div></body></html>'
    layout = Admin::MessageTemplate.create! name: 'test email layout', message_type: :email, template_type: :layout,
                                            template: t, current_admin: @admin

    t = <<~END_TEXT
      This is some content.

      Related to master_id {{master_id}}. This is a name: {{name}}.
    END_TEXT

    Admin::MessageTemplate.create! name: 'test email content', message_type: :email, template_type: :content,
                                   template: t, current_admin: @admin

    res = layout.generate content_template_name: 'test email content',
                          data: { master_id: @master.id, 'name' => 'test name' }
    expected_text = <<~END_TEXT
      <html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content.</p>

      <p>Related to master_id #{@master.id}. This is a name: Test Name.</p></div></body></html>
    END_TEXT

    expect(res).to eq expected_text.strip
  end

  it 'generates a message with master and associations data' do
    create_item
    let_user_create :player_contacts
    master = @player_info.master
    master.current_user = @user
    pn = '(123)456-7890'
    master.player_contacts.create! data: pn, rec_type: :phone, rank: 10
    master.player_contacts.create! data: pn + ' ext 123', rec_type: :phone, rank: 5
    master.player_contacts.create! data: 'abc@def.xyz', rec_type: :email, rank: 10

    expect(master.player_contact_phones.first.data).to eq pn

    df = @user.user_preference.pattern_for_date_time_format
    tz = ActiveSupport::TimeZone.new('Eastern Time (US & Canada)')

    dateformatted = tz.parse(@player_info.created_at.to_s).strftime(df).gsub('  ', ' ')

    t = '<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div>{{main_content}}</div></body></html>'
    layout = Admin::MessageTemplate.create! name: 'test email layout 2', message_type: :email, template_type: :layout,
                                            template: t, current_admin: @admin

    t = '<p>This is some content.</p><p>Related to master_id {{master_id}} for {{player_info.created_at}} by {{player_info.user_email}}. This is a name: {{player_info.first_name}} and {{player_contact_phones.data}}.</p>'
    Admin::MessageTemplate.create! name: 'test email content 2', message_type: :email, template_type: :content,
                                   template: t, current_admin: @admin

    # Should work with either master or a record specified as data
    res = layout.generate content_template_name: 'test email content 2', data: master
    expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content.</p><p>Related to master_id #{master.id} for #{dateformatted} by #{@player_info.user_email}. This is a name: #{@player_info.first_name.captionize} and #{pn}.</p></div></body></html>"
    puts res, expected_text unless res == expected_text
    expect(res).to eq expected_text

    res = layout.generate content_template_name: 'test email content 2', data: @player_info
    expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content.</p><p>Related to master_id #{master.id} for #{dateformatted} by #{@player_info.user_email}. This is a name: #{@player_info.first_name.captionize} and #{pn}.</p></div></body></html>"
    expect(res).to eq expected_text
  end

  it 'generates a message with a text template' do
    t = '<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div>{{main_content}}</div></body></html>'
    layout = Admin::MessageTemplate.create! name: 'test email layout', message_type: :email, template_type: :layout,
                                            template: t, current_admin: @admin

    t = '<p>This is some content.</p><p>Related to master_id {{master_id}}. This is a name: {{name}}.</p>'
    # Admin::MessageTemplate.create! name: 'test email content', message_type: :email, template_type: :content, template: t, current_admin: @admin
    expect do
      layout.generate data: { master_id: @master.id, 'name' => 'test name' }
    end.to raise_error FphsException

    res = layout.generate content_template_text: t, data: { master: @master, 'name' => 'test name bob' }
    expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content.</p><p>Related to master_id #{@master.id}. This is a name: Test Name Bob.</p></div></body></html>"

    expect(res).to eq expected_text
  end

  it 'substitutes user fields' do
    t = '<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div>{{main_content}}</div></body></html>'
    layout = Admin::MessageTemplate.create! name: 'test email layout', message_type: :email, template_type: :layout,
                                            template: t, current_admin: @admin

    t = '<p>This is some content.</p><p>Related to master_id {{master_id}}. This is a name: {{name}}. Done by current user: {{current_user.first_name}}.</p>'
    # Admin::MessageTemplate.create! name: 'test email content', message_type: :email, template_type: :content, template: t, current_admin: @admin
    expect do
      layout.generate data: { master_id: @master.id, 'name' => 'test name' }
    end.to raise_error FphsException

    res = layout.generate content_template_text: t, data: { master: @master, 'name' => 'test name bob' }
    expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content.</p><p>Related to master_id #{@master.id}. This is a name: Test Name Bob. Done by current user: #{@master.current_user.first_name.capitalize}.</p></div></body></html>"

    expect(res).to eq expected_text
  end

  it 'provides formatting options for substituted fields' do
    t = '<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div>{{main_content}}</div></body></html>'
    layout = Admin::MessageTemplate.create! name: 'test email layout', message_type: :email, template_type: :layout,
                                            template: t, current_admin: @admin

    t = '<p>This is some content.</p><p>Related to master_id {{master_id}}. This is a name: {{name::uppercase}}.</p>'

    res = layout.generate content_template_text: t, data: { master_id: @master.id, 'name' => 'test name bob' }
    expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content.</p><p>Related to master_id #{@master.id}. This is a name: TEST NAME BOB.</p></div></body></html>"

    expect(res).to eq expected_text

    t = '<p>This is some content.</p><p>Related to master_id {{master_id}}. This is a name: {{name::uppercase::3}}. Split {{piped::split_pipe::1}}. Is data {{hash.key2}}. Is array {{array::2}} or {{array.1.key}} or {{array.3}}. JSON {{json.json_parse.jkey3.1}}</p>'

    use_data = {
      master_id: @master.id,
      'name' => 'test name bob',
      'piped' => 'data 1|data 2|data 3',
      'hash' => { key1: 123, key2: 456, key3: 789 },
      'array' => ['55', { key: '66' }, '77', '88'],
      'json' => '{"jkey1": 22, "jkey2": "abc", "jkey3": [1230,4560]}'
    }
    res = layout.generate content_template_text: t, data: use_data
    expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content.</p><p>Related to master_id #{@master.id}. This is a name: TEST. Split data 2. Is data 456. Is array 77 or 66 or 88. JSON 4560</p></div></body></html>"

    expect(res).to eq expected_text
  end

  it 'generates UI blocks' do
    t = '<div><p>This is a UI block</p><p>It shows the base url {{base_url}}</p></div>'
    template = Admin::MessageTemplate.create! name: 'test ui content', message_type: :plain, template_type: :content,
                                              template: t, current_admin: @admin

    expect(template.name).to eq 'test ui content'

    res = Admin::MessageTemplate.generate_content content_template_name: 'test ui content', data: {}
    expected_text = "<div><p>This is a UI block</p><p>It shows the base url #{Settings::BaseUrl}</p></div>"

    expect(res).to eq expected_text
  end

  it 'embeds reports' do
    create_reports
    rn = @report1.alt_resource_name
    @master.current_user = @user

    expect(@item_flag).not_to be nil

    Admin::UserAccessControl.create! app_type: @user.app_type, access: :read, resource_type: :general,
                                     resource_name: :view_reports, current_admin: @admin

    check_reports_accessible

    t = '<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div>{{main_content}}</div></body></html>'
    layout = Admin::MessageTemplate.create! name: 'test email layout', message_type: :email, template_type: :layout,
                                            template: t, current_admin: @admin

    t = "<p>This is some content.</p><p>Related to master_id {{master_id}}. This is a name: {{name::uppercase}}.</p>{{embedded_report_#{rn}}}<br/>"

    res = layout.generate content_template_text: t,
                          data: { master_id: @master.id, 'name' => 'test name bob', id: -1, original_item: { id: -1 } }

    expect(res).to include '<table '
  end

  it 'generates a message with a model reference' do
    create_item
    let_user_create :player_contacts
    master = @player_info.master
    master.current_user = @user

    pn = '(123)456-7890'
    pc1 = master.player_contacts.create! data: pn, rec_type: :phone, rank: 10
    pc2 = @player_contact = master.player_contacts.create! data: pn + ' ext 123', rec_type: :phone, rank: 5
    pc3 = master.player_contacts.create! data: 'abc@def.xyz', rec_type: :email, rank: 10

    setup_access :activity_log__player_contact_phones, user: @user
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, user: @user
    setup_access :activity_log__player_contact_phone__blank, resource_type: :activity_log_type, user: @user
    @activity_log = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                                select_who: 'user', master: @player_contact.master)
    @activity_log.extra_log_type_config.references = {
      player_contact: {
        player_contact: {
          from: 'this',
          add: 'many'
        }
      },
      activity_log__player_contact_phone: {
        activity_log__player_contact_phone: {
          from: 'this',
          add: 'one_to_this'
        }
      }
    }

    @activity_log2 = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                                 select_who: 'user', master: @player_contact.master)
    ModelReference.create_with(@activity_log2, pc3, force_create: true)
    ModelReference.create_with(@activity_log, @activity_log2, force_create: true)

    expect(pc1.data).to eq pn

    ModelReference.create_with(@activity_log, pc1, force_create: true)
    ModelReference.create_with(@activity_log, pc2, force_create: true)
    pn_ref1 = pc2.data
    expect(@activity_log.model_references(ref_order: { id: :desc }).first.to_record.data).to eq pn_ref1

    df = @user.user_preference.pattern_for_date_time_format
    tz = ActiveSupport::TimeZone.new('Eastern Time (US & Canada)')

    dateformatted = tz.parse(@player_info.created_at.to_s).strftime(df).gsub('  ', ' ')

    t = '<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div>{{main_content}}</div></body></html>'
    layout = Admin::MessageTemplate.create! name: 'test email layout 2', message_type: :email, template_type: :layout,
                                            template: t, current_admin: @admin

    t = '<p>This is some content.</p><p>Related to master_id {{master_id}} for {{player_info.created_at}} by {{player_info.user_email}}. This is a name: {{player_info.first_name}} and {{player_contact_phones.data}} and {{latest_reference.data}} and {{activity_log__player_contact_phones.player_contact.data}}.</p>'
    Admin::MessageTemplate.create! name: 'test email content 2', message_type: :email, template_type: :content,
                                   template: t, current_admin: @admin

    res = layout.generate content_template_name: 'test email content 2', data: @activity_log
    expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content.</p><p>Related to master_id #{master.id} for #{dateformatted} by #{@player_info.user_email}. This is a name: #{@player_info.first_name.captionize} and #{pn} and #{pn_ref1} and #{@player_contact.data}.</p></div></body></html>"

    expect(res).to eq expected_text
  end

  it 'stress tests creating many' do
    test_times = 10

    txt = "A short message with a generated URL https://www.server.tld/join-us/?test_id={{ids.msid}}\nThanks!"
    last_msid = (Master.order(msid: :desc).first.msid || 123) + 1

    masters = []

    test_times.times do
      master = Master.create! current_user: @user, msid: last_msid
      masters << master
      master.player_contacts.create! data: '(123)123-1234', rec_type: :phone, rank: 10
      master.player_contacts.create! data: '(123)123-1234 alt', rec_type: :phone, rank: 5
      last_msid += 1
    end

    expect(masters.length).to eq test_times

    t = Benchmark.realtime do
      masters.each do |master|
        data = Formatter::Substitution.setup_data(master.player_contacts[0], master.player_contacts[1])
        Formatter::Substitution.substitute txt.dup, data: data, tag_subs: nil
      end
    end

    puts "It took #{t} seconds to create #{test_times} templates"

    expect(t).to be < 3
  end
end
