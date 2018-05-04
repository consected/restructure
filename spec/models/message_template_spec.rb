require 'rails_helper'

RSpec.describe Admin::MessageTemplate, type: :model do

  include ModelSupport

  before :all do
    create_admin
    rec_user, _ = create_user
    create_user
    seed_database

    Admin::MessageTemplate.where(name: 'test email layout').delete_all
    Admin::MessageTemplate.where(name: 'test email content').delete_all
  end

  it "generates a message" do

    t = '<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div>{{main_content}}</div></body></html>'
    layout = Admin::MessageTemplate.create! name: 'test email layout', message_type: :email, template_type: :layout, template: t, current_admin: @admin

    t = '<p>This is some content.</p><p>Related to master_id {{master_id}}. This is a name: {{name}}.</p>'
    content = Admin::MessageTemplate.create! name: 'test email content', message_type: :email, template_type: :content, template: t, current_admin: @admin

    res = layout.generate content_template_name: 'test email content', data: {master_id: 123456, 'name' => 'test name'}
    expected_text = "<html><head><style>body {font-family: sans-serif;}</style></head><body><h1>Test Email</h1><div><p>This is some content.</p><p>Related to master_id <span>123456</span>. This is a name: <span>test name</span>.</p></div></body></html>"

    expect(res).to eq expected_text
  end

end
