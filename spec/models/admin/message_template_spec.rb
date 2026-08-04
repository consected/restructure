# frozen_string_literal: true

require 'rails_helper'

# Covers message template rendering, substitutions, and stored XSS protection for generated HTML.

RSpec.describe Admin::MessageTemplate, type: :model do
  include MasterSupport
  include ModelSupport
  include PlayerInfoSupport
  include ReportSupport
  include ItemFlagSupport

  before :all do
    seed_database # to ensure embedded reports work
    create_admin
    create_user
    create_master
  end

  before :example do
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
    master.player_contacts.create! data: "#{pn} ext 123", rec_type: :phone, rank: 5
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
    pc2 = @player_contact = master.player_contacts.create! data: "#{pn} ext 123", rec_type: :phone, rank: 5
    pc3 = master.player_contacts.create! data: 'abc@def.xyz', rec_type: :email, rank: 10

    setup_access :activity_log__player_contact_phones, user: @user
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, user: @user
    setup_access :activity_log__player_contact_phone__blank_log, resource_type: :activity_log_type, user: @user
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

  # Stored XSS mitigation: generate_content must refuse to return text that
  # contains tags or attributes capable of executing script when rendered as
  # HTML on public info pages, dialogs, or emails.
  describe 'stored XSS protection' do
    def payloads
      [
        '<script>alert(1)</script>',
        '<SCRIPT src="//evil"></SCRIPT>',
        '<iframe src="//evil"></iframe>',
        '<frame src="//evil">',
        '<frameset><frame></frameset>',
        '<object data="//evil"></object>',
        '<embed src="//evil">',
        '<a href="javascript:alert(1)">x</a>',
        '<a href="javascript&#x3A;alert(1)">x</a>',
        '<iframe srcdoc="<script>alert(1)</script>"></iframe>',
        '<img src="x" onerror="alert(1)">',
        '<svg onload="alert(1)">',
        '<body onload="alert(1)">',
        '<meta http-equiv="refresh" content="0;url=javascript:alert(1)">',
        '<meta http-equiv="refresh" content="0; url=\'javascript:alert(1)\'">',
        '<meta http-equiv="refresh" content="0; url=&quot;javascript:alert(1)&quot;">',
        '<meta http-equiv="refresh" content="0;url=https://evil.example">',
        '<meta http-equiv="refresh" content="0;url=data:text/html,%3Ch1%3Ephish%3C/h1%3E">'
      ]
    end
    it 'raises when generated content contains XSS payload}' do
      payloads.each do |payload|
        Admin::MessageTemplate.create! name: 'xss content', message_type: :email, template_type: :content,
                                       template: payload, current_admin: @admin

        expect do
          Admin::MessageTemplate.generate_content content_template_name: 'xss content'
        end.to raise_error(FphsException, /disallowed tag or attribute/)
      end
    end

    it 'raises when layout generation substitutes dangerous HTML into the rendered output' do
      layout = Admin::MessageTemplate.new name: 'test layout', message_type: :email, template_type: :layout,
                                          template: '<html><body>{{main_content}}</body></html>'

      expect do
        layout.generate content_template_text: '<p>{{payload}}</p>',
                        data: { payload: '<img src="x" onerror="alert(1)">' },
                        markdown_to_html: false
      end.to raise_error(FphsException, /disallowed tag or attribute/)
    end

    it 'allows safe HTML and markdown content' do
      Admin::MessageTemplate.create! name: 'safe content', message_type: :email, template_type: :content,
                                     template: '<h1>Hello</h1><p>Safe <strong>content</strong>.</p>',
                                     current_admin: @admin

      res = Admin::MessageTemplate.generate_content content_template_name: 'safe content'
      expect(res).to include '<h1>Hello</h1>'
    end

    it 'allows safe email layouts with standard meta, src, and href attributes' do
      layout_template = <<~HTML
        <html xmlns="http://www.w3.org/1999/xhtml">
          <head>
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
          </head>
          <body>
            <div class="header"><img src="http://localhost:3000/logo.png" /></div>
            <div class="main-content">{{main_content}}</div>
          </body>
        </html>
      HTML

      layout = Admin::MessageTemplate.new name: 'safe layout', message_type: :email, template_type: :layout,
                                          template: layout_template

      expect do
        layout.generate content_template_text: '<p>Read <a href="https://example.test/page">more</a>.</p>'
      end.not_to raise_error
    end

    it 'bypasses XSS check if check_xss is false' do
      Admin::MessageTemplate.create! name: 'js content', message_type: :plain, template_type: :content,
                                     template: 'let online = true; onerror=alert;',
                                     current_admin: @admin

      res = Admin::MessageTemplate.generate_content content_template_name: 'js content', check_xss: false
      expect(res).to include 'let online = true;'
    end
  end
end
