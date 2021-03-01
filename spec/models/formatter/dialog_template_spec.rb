require 'rails_helper'

RSpec.describe Formatter::DialogTemplate, type: :model do
  include ModelSupport
  include PlayerContactSupport

  it 'generates dialog text from a template' do
    seed_database
    create_user
    create_master
    create_item

    ca = @player_contact.created_at

    t = <<~END_TEXT
            ## Simple Dialog Template
      #{'      '}
            This is a simple dialog template for {{data}}
    END_TEXT

    expected_text = Formatter::Substitution.text_to_html(t).gsub('{{data}}', "<em class=\"all_caps\">#{@player_contact.data}</em>")

    dt = Admin::MessageTemplate.create! name: 'test dialog', message_type: :dialog, template_type: :content, template: t, current_admin: @admin

    dmsg = Formatter::DialogTemplate.generate_message(dt.name, @player_contact)

    expect(dmsg).to eq expected_text
  end

  it 'generates versioned dialog text from a template' do
    seed_database
    create_user
    create_master

    ts1 = DateTime.now
    create_item
    pc1 = @player_contact

    t = <<~END_TEXT
      ## Simple Dialog Template

      This is a simple dialog template for {{data}}
    END_TEXT

    dt = Admin::MessageTemplate.create! name: 'test dialog', message_type: :dialog, template_type: :content, template: t, current_admin: @admin

    dmsg1 = Formatter::DialogTemplate.generate_message(dt.name, pc1)
    expected_text1 = Formatter::Substitution.text_to_html(t).gsub('{{data}}', "<em class=\"all_caps\">#{pc1.data}</em>")
    expect(dmsg1).to eq expected_text1

    sleep 2
    ts2 = DateTime.now
    create_item
    pc2 = @player_contact

    t = <<~END_TEXT
      ## Simple Dialog Template 2

      This is the second simple dialog template for {{data}}
    END_TEXT

    dt.update! template: t, current_admin: @admin

    dmsg2 = Formatter::DialogTemplate.generate_message(dt.name, pc2)
    expected_text2 = Formatter::Substitution.text_to_html(t).gsub('{{data}}', "<em class=\"all_caps\">#{pc2.data}</em>")
    expect(dmsg2).to eq expected_text2

    expect(pc1.created_at).to be < pc2.created_at
    mt = Admin::MessageTemplate.active.dialog_templates.where(name: 'test dialog').first
    versioned_mt = mt.versioned(pc1.created_at)
    expect(versioned_mt).not_to be_nil

    dmsg1 = Formatter::DialogTemplate.generate_message(dt.name, pc1)
    expect(dmsg1).to eq expected_text1
  end
end
