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
    setup_access :player_infos, user: @user

    @player_info = @master.build_player_info(first_name: 'testfn', last_name: 'testln', birth_date: (Time.now - 30.years + 1.day))
    @player_info.force_save!
    @player_info.save!
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
    res = Formatter::Substitution.substitute txt.dup, data:, tag_subs: nil

    expect(res).to eq 'This is a simple test: 12345 abcdef ghijkl "" !!!'
  end

  it 'handles special cases' do
    txt = 'This is a simple test: {{player_info.first_name}} {{player_info.last_name}} {{player_info.subject_age}}'
    data = @player_info
    res = Formatter::Substitution.substitute txt.dup, data:, tag_subs: nil

    expect(res).to eq 'This is a simple test: Testfn Testln 29'
  end

  it 'fails if a key is missing from the data' do
    txt = 'This is a simple test: {{int_val}} {{string_key}} {{symbol_key}} "{{blank_val}}" !!!'
    data = {
      int_val: 12_345,
      'string_key' => 'abcdef',
      blank_val: nil
    }

    expect do
      Formatter::Substitution.substitute txt.dup, data:, tag_subs: nil
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
        program_name: LC2Test
        program_id: LC2Test

      new_step:
        label: New Step
        caption_before:
          all_fields: show before all fields
          select_result: 'has a caption before select_result with a {{constants.replace_me}} substitution made. Program {{constants.program_name}} - {{constants.program_id}}'

    END_DEF

    @al_def.current_admin = @admin
    @al_def.save!

    setup_access :activity_log__player_contact_new_elt__new_step, resource_type: :activity_log_type, access: :create, user: @user

    @al_def.reload
    @al_def.option_type_config_for :new_step

    @activity_log = @player_contact.activity_log__player_contact_new_elts.create!(select_call_direction: 'from player',
                                                                                  select_who: 'user',
                                                                                  master:,
                                                                                  extra_log_type: 'new_step')

    expect(@activity_log.versioned_definition.options_constants[:replace_me]).to eq 'super special'

    caption = @activity_log.extra_log_type_config.caption_before[:select_result][:caption]
    expected_text = '<p>has a caption before select_result with a super special substitution made. Program Lc2 Test - LC2Test</p>'

    res = Formatter::Substitution.substitute(caption, data: @activity_log, tag_subs: nil)

    expect(res).to eq expected_text
  end

  it 'substitutes embedded items' do
    let_user_create :player_contacts
    create_item
    master = @player_contact.master
    master.current_user = @user

    expect(@player_contact.data).not_to be_blank

    setup_access :activity_log__player_contact_new_elts, user: @user

    @al_def.extra_log_types = <<~END_DEF
      _constants:
        replace_me: embedding value

      new_step2:
        label: New Step2
        embed:
          resource_name: player_contacts
          resource_id: #{@player_contact.id}
        caption_before:
          all_fields: show before all fields
          select_result: 'has a new caption before select_result with {{embedded_item.data}}'

    END_DEF

    @al_def.current_admin = @admin
    @al_def.save!

    setup_access :activity_log__player_contact_new_elt__new_step2, resource_type: :activity_log_type, access: :create, user: @user

    @al_def.reload
    @al_def.option_type_config_for :new_step

    @activity_log = @player_contact.activity_log__player_contact_new_elts.create!(select_call_direction: 'from player',
                                                                                  select_who: 'user',
                                                                                  master:,
                                                                                  extra_log_type: 'new_step2')

    caption = @activity_log.extra_log_type_config.caption_before[:select_result][:caption]
    expected_text = "<p>has a new caption before select_result with #{@player_contact.data}</p>"

    res = Formatter::Substitution.substitute(caption, data: @activity_log, tag_subs: nil)

    expect(res).to eq expected_text
  end

  it 'substitutes times and dates using user preferences for formatting' do
    # Day before daylight savings time starts. Standard time is UTC -5 hours
    date = Date.parse('2015-03-07')
    time = Time.parse('14:56:04 EST')
    res = Formatter::DateTime.format({ date:, time:, zone: nil }, show_timezone: nil, current_user: @user)

    # expect(res).to eq '03/07/2022 2:56 pm EST'

    txt = 'This is a simple test: {{int_val}} {{a_date}} {{a_time}} - {{a_time::time_sec}}'
    data = {
      int_val: 12_345,
      a_time: time,
      a_date: date,
      current_user: @user
    }

    res = Formatter::Substitution.substitute txt.dup, data:, tag_subs: nil

    expect(res).to eq 'This is a simple test: 12345 03/07/2015 2:56 pm - 2:56:04 pm'
  end

  it 'substitutes current user role names' do
    create_user_role 'test - role substitution', user: @user
    txt = 'This is a role name test: {{current_user_email}} has role {{current_user_roles.test___role_substitution}}'
    data = {
      current_user: @user
    }

    res = Formatter::Substitution.substitute txt.dup, data:, tag_subs: nil
    expect(res).to eq "This is a role name test: #{@user.email} has role #{@user.role_names.first}"

    txt = 'This is a role name test: {{current_user_email}} has role {{current_user_roles.test___role_substitution}} - {{#if current_user_roles.test___role_substitution}}has role{{else}}no{{/if}} - {{#if current_user_role_no_test___role_substitution}}yes{{else}}no role{{/if}}'
    res = Formatter::Substitution.substitute txt.dup, data:, tag_subs: nil
    expect(res).to eq "This is a role name test: #{@user.email} has role #{@user.role_names.first} - has role - no role"
  end

  it 'provides conditional display using an if block' do
    txt = <<~END_TEXT
      This is a simple test: {{int_val}}

      {{#if some_text}}shows {{some_text}}{{/if}} or {{#if truthy_val}}some other text{{/if}}

      {{#if true_val}}shows true{{/if}}
      {{#if false_val}}does not show false{{else}}but does show {{int_val}} else{{/if}}
      {{#if nil_val}}ignores nils{{else}}nil was skipped{{/if}}
      {{#if blank_val}}ignores blanks{{else}}blank was skipped{{/if}}

      {{#if true_val}}
      It can also handle multiple
      lines in the results.
      OK?
      {{/if}}

      {{#if false_val}}Not shown{{else}}It can also handle multiple
      lines in the else results.
      Good?{{/if}}

      {{#if true_val}}{{int_val}}{{/if}}
      {{#if false_val}}{{int_val}}{{/if}}

      {{#if false_val}}Not shown{{else if true_val}}Else If shown{{else}}Not else{{/if}}
      {{#if true_val}}This shown{{else if true_val}}Else If shown{{else}}Not else{{/if}}
      {{#if false_val}}Not shown{{else if false_val}}Else If shown{{else}}Show else{{/if}}

      All done!
    END_TEXT

    if_blocks = txt.scan Formatter::Substitution::IfBlockRegEx

    # 13 blocks each of 7 elements
    expect(if_blocks.length).to eq 13
    expect(if_blocks[0].length).to eq 8
    expect(if_blocks[0][0]).to eq '{{#if some_text}}shows {{some_text}}{{/if}}'
    expect(if_blocks[0][1]).to eq 'some_text'
    expect(if_blocks[0][2]).to eq 'shows {{some_text}}'
    expect(if_blocks[0][3]).to be nil
    expect(if_blocks[0][4]).to be nil

    expect(if_blocks[1][0]).to eq '{{#if truthy_val}}some other text{{/if}}'
    expect(if_blocks[1][1]).to eq 'truthy_val'
    expect(if_blocks[1][2]).to eq 'some other text'
    expect(if_blocks[1][3]).to be nil
    expect(if_blocks[1][4]).to be nil

    expect(if_blocks[3][0]).to eq '{{#if false_val}}does not show false{{else}}but does show {{int_val}} else{{/if}}'
    expect(if_blocks[3][1]).to eq 'false_val'
    expect(if_blocks[3][2]).to eq 'does not show false'
    expect(if_blocks[3][6]).to be_truthy
    expect(if_blocks[3][7]).to eq 'but does show {{int_val}} else'

    expect(if_blocks[6][0]).to eq %({{#if true_val}}
It can also handle multiple
lines in the results.
OK?
{{/if}})

    expect(if_blocks[6][1]).to eq 'true_val'
    expect(if_blocks[6][2]).to eq %(
It can also handle multiple
lines in the results.
OK?
)

    expect(if_blocks[6][3]).to be nil
    expect(if_blocks[6][4]).to eq nil

    expect(if_blocks[7][0]).to eq %({{#if false_val}}Not shown{{else}}It can also handle multiple
lines in the else results.
Good?{{/if}})
    expect(if_blocks[7][1]).to eq 'false_val'
    expect(if_blocks[7][2]).to eq 'Not shown'
    expect(if_blocks[7][6]).to be_truthy

    expect(if_blocks[7][7]).to eq %(It can also handle multiple
lines in the else results.
Good?)

    # Now test else if
    expect(if_blocks[10].length).to eq 8
    expect(if_blocks[10][0]).to eq '{{#if false_val}}Not shown{{else if true_val}}Else If shown{{else}}Not else{{/if}}'
    expect(if_blocks[10][1]).to eq 'false_val'
    expect(if_blocks[10][2]).to eq 'Not shown'
    expect(if_blocks[10][3]).to eq '{{else if true_val}}Else If shown'
    expect(if_blocks[10][4]).to eq 'true_val'
    expect(if_blocks[10][5]).to eq 'Else If shown'
    expect(if_blocks[10][6]).to be_truthy
    expect(if_blocks[10][7]).to eq 'Not else'

    # Now test else if
    expect(if_blocks[12].length).to eq 8
    expect(if_blocks[12][0]).to eq '{{#if false_val}}Not shown{{else if false_val}}Else If shown{{else}}Show else{{/if}}'
    expect(if_blocks[12][1]).to eq 'false_val'
    expect(if_blocks[12][2]).to eq 'Not shown'
    expect(if_blocks[12][3]).to eq '{{else if false_val}}Else If shown'
    expect(if_blocks[12][4]).to eq 'false_val'
    expect(if_blocks[12][5]).to eq 'Else If shown'
    expect(if_blocks[12][6]).to be_truthy
    expect(if_blocks[12][7]).to eq 'Show else'

    data = {
      int_val: 12_345,
      some_text: 'this is optional',
      truthy_val: 0,
      true_val: true,
      false_val: false,
      nil_val: nil,
      blank_val: ''
    }

    res = Formatter::Substitution.substitute txt.dup, data:, tag_subs: nil

    expect(res).to eq <<~END_TEXT
      This is a simple test: 12345

      shows this is optional or some other text

      shows true
      but does show 12345 else
      nil was skipped
      blank was skipped


      It can also handle multiple
      lines in the results.
      OK?


      It can also handle multiple
      lines in the else results.
      Good?

      12345


      Else If shown
      This shown
      Show else

      All done!
    END_TEXT
  end
end
