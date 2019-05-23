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
    expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content.</p><p>Related to master_id 123456. This is a name: test name.</p></div></body></html>"

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

    df = @user.user_preference.pattern_for_date_time_format
    dateformatted = @player_info.created_at.strftime(df).gsub('  ', ' ')


    t = '<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div>{{main_content}}</div></body></html>'
    layout = Admin::MessageTemplate.create! name: 'test email layout 2', message_type: :email, template_type: :layout, template: t, current_admin: @admin

    t = '<p>This is some content.</p><p>Related to master_id {{master_id}} for {{player_info.created_at}}. This is a name: {{player_info.first_name}} and {{player_contact_phones.data}}.</p>'
    Admin::MessageTemplate.create! name: 'test email content 2', message_type: :email, template_type: :content, template: t, current_admin: @admin

    res = layout.generate content_template_name: 'test email content 2', data: master
    expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content.</p><p>Related to master_id #{master.id} for #{dateformatted}. This is a name: #{@player_info.first_name} and #{pn}.</p></div></body></html>"

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
    expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content.</p><p>Related to master_id 12345678. This is a name: test name bob.</p></div></body></html>"

    expect(res).to eq expected_text
  end

end
