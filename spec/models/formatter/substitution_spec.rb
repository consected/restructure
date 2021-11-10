# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Formatter::Substitution, type: :model do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport

  AlNameGenNewTest = 'Gen New Test ELT'

  before :context do
    SetupHelper.setup_al_gen_tests AlNameGenNewTest, 'new_elt', 'player_contact'
  end

  before :example do
    @al_def = ActivityLog.active.where(name: AlNameGenNewTest).first

    create_admin
    create_user
    create_master
    create_items
  end

  it 'substitutes hash values into text' do
    txt = 'This is a simple test: {{int_val}} {{string_key}} {{symbol_key}} "{{blank_val}}" !!!'
    data = {
      int_val: 12_345,
      'string_key' => 'abcdef',
      symbol_key: 'ghijkl',
      blank_val: nil
    }
    res = Formatter::Substitution.substitute txt.dup, data: data, tag_subs: nil

    expect(res).to eq 'This is a simple test: 12345 abcdef ghijkl "" !!!'
  end

  it 'fails if a key is missing from the data' do
    txt = 'This is a simple test: {{int_val}} {{string_key}} {{symbol_key}} "{{blank_val}}" !!!'
    data = {
      int_val: 12_345,
      'string_key' => 'abcdef',
      blank_val: nil
    }

    expect do
      Formatter::Substitution.substitute txt.dup, data: data, tag_subs: nil
    end.to raise_error FphsException
  end

  it 'substitutes from object variables and attributes' do
    let_user_create :player_contacts
    create_item
    master = @player_contact.master
    master.current_user = @user

    setup_access :activity_log__player_contact_new_elts, user: @user

    @al_def.extra_log_types = <<~END_DEF
      _constants:
        replace_me: super special

      new_step:
        label: New Step
        caption_before:
          all_fields: show before all fields
          select_result: 'has a caption before select_result with a {{constants.replace_me}} substitution made'

    END_DEF

    @al_def.current_admin = @admin
    @al_def.save!

    setup_access :activity_log__player_contact_new_elt__new_step, resource_type: :activity_log_type, access: :create, user: @user

    @al_def.reload
    @al_def.option_type_config_for :new_step

    @activity_log = @player_contact.activity_log__player_contact_new_elts.create!(select_call_direction: 'from player',
                                                                                  select_who: 'user',
                                                                                  master: master,
                                                                                  extra_log_type: 'new_step')

    expect(@activity_log.versioned_definition.options_constants[:replace_me]).to eq 'super special'

    caption = @activity_log.extra_log_type_config.caption_before[:select_result][:caption]
    expected_text = "<p>has a caption before select_result with a super special substitution made</p>\n"

    res = Formatter::Substitution.substitute(caption, data: @activity_log, tag_subs: nil)

    expect(res).to eq expected_text
  end
end
