require 'rails_helper'

RSpec.describe Admin::MessageTemplate, type: :model do

  include ModelSupport
  include PlayerInfoSupport


  before :all do
    create_admin
    create_user
    seed_database
    l = Admin::MessageTemplate.last.id
    Admin::MessageTemplate.where(name: 'test email layout').update_all(name: "test old layout #{l}")
    Admin::MessageTemplate.where(name: 'test email content').update_all(name: "test old content #{l}")
  end

  it "generates a message" do

    t = '<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div>{{main_content}}</div></body></html>'
    layout = Admin::MessageTemplate.create! name: 'test email layout', message_type: :email, template_type: :layout, template: t, current_admin: @admin

    t = '<p>This is some content.</p><p>Related to master_id {{master_id}}. This is a name: {{name}}.</p>'
    Admin::MessageTemplate.create! name: 'test email content', message_type: :email, template_type: :content, template: t, current_admin: @admin

    res = layout.generate content_template_name: 'test email content', data: {master_id: 123456, 'name' => 'test name'}
    expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content.</p><p>Related to master_id 123456. This is a name: Test Name.</p></div></body></html>"

    expect(res).to eq expected_text
  end

  it "generates a message with master and associations data" do

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
    layout = Admin::MessageTemplate.create! name: 'test email layout 2', message_type: :email, template_type: :layout, template: t, current_admin: @admin

    t = '<p>This is some content.</p><p>Related to master_id {{master_id}} for {{player_info.created_at}}. This is a name: {{player_info.first_name}} and {{player_contact_phones.data}}.</p>'
    Admin::MessageTemplate.create! name: 'test email content 2', message_type: :email, template_type: :content, template: t, current_admin: @admin

    # Should work with either master or a record specified as data
    res = layout.generate content_template_name: 'test email content 2', data: master
    expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content.</p><p>Related to master_id #{master.id} for #{dateformatted}. This is a name: #{@player_info.first_name.titleize} and #{pn}.</p></div></body></html>"

    res = layout.generate content_template_name: 'test email content 2', data: @player_info
    expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content.</p><p>Related to master_id #{master.id} for #{dateformatted}. This is a name: #{@player_info.first_name.titleize} and #{pn}.</p></div></body></html>"

    expect(res).to eq expected_text
  end

  it "generates a message with a text template" do

    t = '<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div>{{main_content}}</div></body></html>'
    layout = Admin::MessageTemplate.create! name: 'test email layout', message_type: :email, template_type: :layout, template: t, current_admin: @admin

    t = '<p>This is some content.</p><p>Related to master_id {{master_id}}. This is a name: {{name}}.</p>'
    # Admin::MessageTemplate.create! name: 'test email content', message_type: :email, template_type: :content, template: t, current_admin: @admin
    expect {
      layout.generate data: {master_id: 123456, 'name' => 'test name'}
    }.to raise_error FphsException

    res = layout.generate content_template_text: t, data: {master_id: 12345678, 'name' => 'test name bob'}
    expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content.</p><p>Related to master_id 12345678. This is a name: Test Name Bob.</p></div></body></html>"

    expect(res).to eq expected_text
  end

  it "provides formatting options for substituted fields" do

    t = '<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div>{{main_content}}</div></body></html>'
    layout = Admin::MessageTemplate.create! name: 'test email layout', message_type: :email, template_type: :layout, template: t, current_admin: @admin

    t = '<p>This is some content.</p><p>Related to master_id {{master_id}}. This is a name: {{name::uppercase}}.</p>'

    res = layout.generate content_template_text: t, data: {master_id: 12345678, 'name' => 'test name bob'}
    expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content.</p><p>Related to master_id 12345678. This is a name: TEST NAME BOB.</p></div></body></html>"

    expect(res).to eq expected_text

    t = '<p>This is some content.</p><p>Related to master_id {{master_id}}. This is a name: {{name::uppercase::3}}.</p>'

    res = layout.generate content_template_text: t, data: {master_id: 12345678, 'name' => 'test name bob'}
    expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content.</p><p>Related to master_id 12345678. This is a name: TEST.</p></div></body></html>"

    expect(res).to eq expected_text

  end

  it "stress tests creating many" do

    test_times = 10

    txt = "A short message with a generated URL https://footballplayershealth.harvard.edu/join-us/?test_id={{ids.msid}}\nThanks!"
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
        data = Admin::MessageTemplate.setup_data(master.player_contacts[0], master.player_contacts[1])
        res = Admin::MessageTemplate.substitute txt.dup, data: data, tag_subs: nil
      end
    end

    puts "It took #{t} seconds to create #{test_times} templates"

    expect(t).to be < 2


  end


end
