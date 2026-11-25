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

  it 'uses the current user preferences for date and time formatters in extra substitutions' do
    @user.user_preference.update!(timezone: 'London', date_format: 'dd/mm/yyyy',
                                  date_time_format: 'dd/mm/yyyy hh:mm am/pm', time_format: '24h:mm')
    value = DateTime.parse('2024-01-15T12:34:56Z')
    formats = [nil, :date, :date_time, :date_time_show_zone, :date_time_with_zone, :time,
               :time_show_zone, :time_with_zone, :time_sec, :time_ignore_zone]

    formats.each do |format|
      suffix = "#{'::' if format}#{format}"
      expected = Formatter::Substitution.substitute("{{value#{suffix}}}",
                                                    data: { value:, current_user: @user }, tag_subs: nil)
      actual = Formatter::Substitution.substitute(
        "{{extra_substitutions.value#{suffix}}}",
        data: { current_user: @user, extra_substitutions: { value: } }, tag_subs: nil
      )

      expect(actual).to eq(expected), "Expected #{format || 'default'} formatting to use the current user's preferences"
    end
  end

  it 'preserves the current user through nested, parsed, and variable hashes' do
    @user.user_preference.update!(timezone: 'London', date_format: 'dd/mm/yyyy',
                                  date_time_format: 'dd/mm/yyyy hh:mm am/pm', time_format: '24h:mm')
    value = '2024-01-15T12:34:56Z'
    data = {
      current_user: @user,
      extra_substitutions: {
        nested: { value: DateTime.parse(value) },
        json: %({"value":"2024-01-15T12:34:56Z"}),
        yaml: "value: '2024-01-15T12:34:56Z'\n"
      },
      variables: { nested: { value: DateTime.parse(value) } }
    }
    tags = [
      '{{extra_substitutions.nested.value::date_time_show_zone}}',
      '{{extra_substitutions.json.json_parse.value::date_time_show_zone}}',
      '{{extra_substitutions.yaml.yaml_parse.value::date_time_show_zone}}',
      '{{variables.nested.value::date_time_show_zone}}'
    ]
    expected = Formatter::Substitution.substitute('{{value::date_time_show_zone}}',
                                                  data: { value:, current_user: @user }, tag_subs: nil)

    tags.each do |tag|
      actual = Formatter::Substitution.substitute(tag, data:, tag_subs: nil)
      expect(actual).to eq(expected), "Expected #{tag} to use the current user's preferences"
    end
  end

  it 'resolves master and current user values from string-keyed hashes' do
    data = Formatter::Substitution.setup_data('master_id' => @master.id, 'current_user_id' => @user.id)

    expect(data[:master]).to be_nil
    expect(data[:current_user_instance]).to eq(@user)

    symbol_keyed_data = Formatter::Substitution.setup_data(master_id: @master.id)
    expect(symbol_keyed_data[:master]).to eq(@master)

    expect do
      Formatter::Substitution.setup_data(master_id: Master.maximum(:id).to_i + 1)
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'lets a user specified inside an extra substitutions hash override the parent user' do
    parent_user = @user
    nested_user, = create_user
    nested_user.user_preference.update!(timezone: 'Eastern Time (US & Canada)', date_format: 'mm/dd/yyyy',
                                        date_time_format: 'mm/dd/yyyy hh:mm am/pm', time_format: 'h:mm am/pm')
    value = DateTime.parse('2024-01-15T12:34:56Z')
    user_contexts = [
      { current_user_id: nested_user.id },
      { current_user_instance: nested_user },
      { current_user: nested_user }
    ]

    user_contexts.each do |user_context|
      data = { current_user: parent_user,
               extra_substitutions: user_context.merge(nested: { value: }) }
      actual = Formatter::Substitution.substitute(
        '{{extra_substitutions.nested.value::date_time_show_zone}}', data:, tag_subs: nil
      )
      expected = Formatter::Substitution.substitute('{{value::date_time_show_zone}}',
                                                    data: { value:, current_user: nested_user }, tag_subs: nil)

      expect(actual).to eq(expected), "Expected #{user_context.keys.first} to override the parent user's preferences"
    end
  end

  it 'resolves an extra substitutions current_user_id without a parent user' do
    nested_user, = create_user
    nested_user.user_preference.update!(timezone: 'Eastern Time (US & Canada)', date_format: 'mm/dd/yyyy',
                                        date_time_format: 'mm/dd/yyyy hh:mm am/pm', time_format: 'h:mm am/pm')
    value = DateTime.parse('2024-01-15T12:34:56Z')
    data = { extra_substitutions: { current_user_id: nested_user.id, nested: { value: } } }

    actual = Formatter::Substitution.substitute(
      '{{extra_substitutions.nested.value::date_time_show_zone}}', data:, tag_subs: nil
    )
    expected = Formatter::Substitution.substitute('{{value::date_time_show_zone}}',
                                                  data: { value:, current_user: nested_user }, tag_subs: nil)

    expect(actual).to eq(expected)
  end

  it 'does not pass a plain hash current_user to date and time formatters' do
    value = DateTime.parse('2024-01-15T12:34:56Z')
    data_cases = [
      ['{{value::date_time}}', { current_user: { id: @user.id }, value: }],
      ['{{extra_substitutions.value::date_time}}',
       { extra_substitutions: { current_user: { id: @user.id }, value: } }]
    ]

    data_cases.each do |tag, data|
      actual = Formatter::Substitution.substitute(tag, data:, tag_subs: nil)
      expected = Formatter::Substitution.substitute('{{value::date_time}}', data: { value: }, tag_subs: nil)

      expect(actual).to eq(expected)
    end
  end

  it 'uses default preferences when current_user_id does not resolve' do
    value = DateTime.parse('2024-01-15T12:34:56Z')
    data = Formatter::Substitution.setup_data(current_user_id: User.maximum(:id).to_i + 1, value:)

    actual = Formatter::Substitution.substitute('{{value::date_time_show_zone}}', data:, tag_subs: nil)
    expected = Formatter::Substitution.substitute('{{value::date_time_show_zone}}', data: { value: }, tag_subs: nil)

    expect(actual).to eq(expected)
  end

  it 'continues to use the associated model current user for association tags' do
    @user.user_preference.update!(timezone: 'London', date_format: 'dd/mm/yyyy',
                                  date_time_format: 'dd/mm/yyyy hh:mm am/pm', time_format: '24h:mm')
    @master.current_user = @user
    expected = Formatter::Substitution.substitute('{{value::date_time_show_zone}}',
                                                  data: { value: @player_contact.created_at, current_user: @user },
                                                  tag_subs: nil)

    actual = Formatter::Substitution.substitute(
      '{{player_contacts.created_at::date_time_show_zone}}', data: @master, tag_subs: nil
    )

    expect(actual).to eq(expected)
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

    # 13 blocks each of 3 capture groups (full match, tag, inner content)
    expect(if_blocks.length).to eq 13
    expect(if_blocks[0].length).to eq 3
    expect(if_blocks[0][0]).to eq '{{#if some_text}}shows {{some_text}}{{/if}}'
    expect(if_blocks[0][1]).to eq 'some_text'
    expect(if_blocks[0][2]).to eq 'shows {{some_text}}'

    expect(if_blocks[1][0]).to eq '{{#if truthy_val}}some other text{{/if}}'
    expect(if_blocks[1][1]).to eq 'truthy_val'
    expect(if_blocks[1][2]).to eq 'some other text'

    expect(if_blocks[3][0]).to eq '{{#if false_val}}does not show false{{else}}but does show {{int_val}} else{{/if}}'
    expect(if_blocks[3][1]).to eq 'false_val'
    expect(if_blocks[3][2]).to eq 'does not show false{{else}}but does show {{int_val}} else'

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

    expect(if_blocks[7][0]).to eq %({{#if false_val}}Not shown{{else}}It can also handle multiple
lines in the else results.
Good?{{/if}})
    expect(if_blocks[7][1]).to eq 'false_val'
    expect(if_blocks[7][2]).to eq %(Not shown{{else}}It can also handle multiple
lines in the else results.
Good?)

    # Now test else if - inner content includes the else if and else clauses
    expect(if_blocks[10].length).to eq 3
    expect(if_blocks[10][0]).to eq '{{#if false_val}}Not shown{{else if true_val}}Else If shown{{else}}Not else{{/if}}'
    expect(if_blocks[10][1]).to eq 'false_val'
    expect(if_blocks[10][2]).to eq 'Not shown{{else if true_val}}Else If shown{{else}}Not else'

    expect(if_blocks[12].length).to eq 3
    expect(if_blocks[12][0]).to eq '{{#if false_val}}Not shown{{else if false_val}}Else If shown{{else}}Show else{{/if}}'
    expect(if_blocks[12][1]).to eq 'false_val'
    expect(if_blocks[12][2]).to eq 'Not shown{{else if false_val}}Else If shown{{else}}Show else'

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

  it 'provides conditional display using an is block' do
    txt = <<~END_TEXT
      This is a simple test: {{int_val}}

      {{#is some_text "==" 'this is optional'}}shows {{some_text}}{{/is}}
      {{#is some_text '!=' "this is optional"}}shows {{some_text}}{{else}}no show {{some_text}}{{/is}}
      {{#is int_val '<' 50}}too large {{int_val}}{{else}}so show {{int_val}} >= 50{{/is}}
      {{#is int_val '<' 50}}too large {{int_val}}{{else is int_val '>' 50000}}{{int_val}} < 50000{{else}}so show {{int_val}}{{/is}}
      {{#is int_val '<' 50}}too large {{int_val}}{{else is int_val '<' 50000}}50 < {{int_val}} < 50000{{else}}no show {{int_val}}{{/is}}
      {{#is int_val '==' null}}is null{{else is int_val '<' 50}}too large {{int_val}}{{else is int_val '<' 50000}}not null and 50 < {{int_val}} < 50000{{else}}no show {{int_val}}{{/is}}
      {{#is int_val '!=' null}}is null{{else is int_val '<' 50}}too large {{int_val}}{{else is int_val '<' 50000}}50 < {{int_val}} < 50000{{else}}no show {{int_val}}{{/is}}
      {{#is arr_val 'includes' "id"}}includes id{{else is arr_val 'includes' "master_id"}}includes master_id{{/is}}
      {{#is arr_val 'includes' "id"}}includes id{{else is arr_val 'includes' "master"}}includes master{{else is arr_val 'includes' "master_id"}}includes master_id{{/is}}
      {{#is arr_val2 'includes' "id"}}includes id{{else is arr_val2 'includes' "master_id"}}includes master_id{{/is}}

      All done!
    END_TEXT

    if_blocks = txt.scan Formatter::Substitution::IsBlockRegEx

    # 10 blocks each of 5 capture groups (full match, tag, op, exp, inner content)
    expect(if_blocks.length).to eq 10
    expect(if_blocks[0].length).to eq 5
    expect(if_blocks[0][0]).to eq '{{#is some_text "==" \'this is optional\'}}shows {{some_text}}{{/is}}'
    expect(if_blocks[0][1]).to eq 'some_text'
    expect(if_blocks[0][2]).to eq '=='
    expect(if_blocks[0][3]).to eq "'this is optional'"
    expect(if_blocks[0][4]).to eq 'shows {{some_text}}'

    expect(if_blocks[1][0]).to eq '{{#is some_text \'!=\' "this is optional"}}shows {{some_text}}{{else}}no show {{some_text}}{{/is}}'
    expect(if_blocks[1][1]).to eq 'some_text'
    expect(if_blocks[1][2]).to eq '!='
    expect(if_blocks[1][3]).to eq '"this is optional"'
    expect(if_blocks[1][4]).to eq 'shows {{some_text}}{{else}}no show {{some_text}}'

    expect(if_blocks[2][0]).to eq "{{#is int_val '<' 50}}too large {{int_val}}{{else}}so show {{int_val}} >= 50{{/is}}"
    expect(if_blocks[2][1]).to eq 'int_val'
    expect(if_blocks[2][2]).to eq '<'
    expect(if_blocks[2][3]).to eq '50'
    expect(if_blocks[2][4]).to eq 'too large {{int_val}}{{else}}so show {{int_val}} >= 50'

    data = {
      int_val: 12_345,
      some_text: 'this is optional',
      truthy_val: 0,
      true_val: true,
      false_val: false,
      nil_val: nil,
      blank_val: '',
      arr_val: ['col1', 'master_id', 'col2', 'col3'],
      arr_val2: ['id', 'master_id', 'col2', 'col3']
    }

    res = Formatter::Substitution.substitute txt.dup, data:, tag_subs: nil

    expect(res).to eq <<~END_TEXT
      This is a simple test: 12345

      shows this is optional
      no show this is optional
      so show 12345 >= 50
      so show 12345
      50 < 12345 < 50000
      not null and 50 < 12345 < 50000
      is null
      includes master_id
      includes master_id
      includes id

      All done!
    END_TEXT
  end

  it 'handles arbitrary number of else if conditions in if blocks' do
    txt = <<~END_TEXT
      {{#if val_a}}A{{else if val_b}}B{{else if val_c}}C{{else if val_d}}D{{else if val_e}}E{{else}}none{{/if}}
    END_TEXT

    # First condition true
    data = { val_a: true, val_b: false, val_c: false, val_d: false, val_e: false }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res.strip).to eq 'A'

    # Second condition true
    data = { val_a: false, val_b: true, val_c: false, val_d: false, val_e: false }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res.strip).to eq 'B'

    # Third condition true
    data = { val_a: false, val_b: false, val_c: true, val_d: false, val_e: false }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res.strip).to eq 'C'

    # Fourth condition true
    data = { val_a: false, val_b: false, val_c: false, val_d: true, val_e: false }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res.strip).to eq 'D'

    # Fifth condition true
    data = { val_a: false, val_b: false, val_c: false, val_d: false, val_e: true }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res.strip).to eq 'E'

    # No conditions true - falls through to else
    data = { val_a: false, val_b: false, val_c: false, val_d: false, val_e: false }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res.strip).to eq 'none'

    # First truthy wins even if later ones are also truthy
    data = { val_a: false, val_b: false, val_c: true, val_d: true, val_e: true }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res.strip).to eq 'C'
  end

  it 'handles arbitrary number of else if conditions without a final else' do
    txt = '{{#if val_a}}A{{else if val_b}}B{{else if val_c}}C{{else if val_d}}D{{/if}}'

    data = { val_a: false, val_b: false, val_c: false, val_d: true }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res).to eq 'D'

    data = { val_a: false, val_b: false, val_c: false, val_d: false }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res).to eq ''
  end

  it 'handles a single if string with at least five else if clauses' do
    txt = '{{#if a}}A{{else if b}}B{{else if c}}C{{else if d}}D{{else if e}}E{{else if f}}F{{else}}none{{/if}}'

    data = { a: true, b: false, c: false, d: false, e: false, f: true }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res).to eq 'A'

    data = { a: false, b: false, c: false, d: false, e: false, f: true }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res).to eq 'F'

    data = { a: false, b: false, c: false, d: false, e: false, f: false }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res).to eq 'none'
  end

  it 'handles arbitrary number of else is conditions in is blocks' do
    txt = <<~END_TEXT
      {{#is val '==' "a"}}A{{else is val '==' "b"}}B{{else is val '==' "c"}}C{{else is val '==' "d"}}D{{else is val '==' "e"}}E{{else}}none{{/is}}
    END_TEXT

    data = { val: 'a' }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res.strip).to eq 'A'

    data = { val: 'b' }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res.strip).to eq 'B'

    data = { val: 'c' }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res.strip).to eq 'C'

    data = { val: 'd' }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res.strip).to eq 'D'

    data = { val: 'e' }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res.strip).to eq 'E'

    data = { val: 'z' }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res.strip).to eq 'none'
  end

  it 'handles arbitrary else is with numeric comparisons' do
    txt = <<~END_TEXT
      {{#is score '>' 90}}excellent{{else is score '>' 80}}great{{else is score '>' 70}}good{{else is score '>' 60}}ok{{else is score '>' 50}}fair{{else}}poor{{/is}}
    END_TEXT

    data = { score: 95 }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res.strip).to eq 'excellent'

    data = { score: 85 }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res.strip).to eq 'great'

    data = { score: 75 }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res.strip).to eq 'good'

    data = { score: 65 }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res.strip).to eq 'ok'

    data = { score: 55 }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res.strip).to eq 'fair'

    data = { score: 30 }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res.strip).to eq 'poor'
  end

  it 'handles multiple if blocks with arbitrary else-if in the same text' do
    txt = <<~END_TEXT
      Result: {{#if x}}X{{else if y}}Y{{else if z}}Z{{/if}} and {{#if a}}A{{else if b}}B{{else if c}}C{{else if d}}D{{/if}}
    END_TEXT

    data = { x: false, y: false, z: true, a: false, b: false, c: false, d: true }
    res = Formatter::Substitution.substitute(txt.dup, data:)
    expect(res.strip).to eq 'Result: Z and D'
  end

  it 'converts a JSON string field to YAML via parse_json and yaml formatters' do
    json_string = '{"name":"Alice","scores":[10,20,30]}'
    txt = '{{json_field::parse_json::yaml}}'
    data = { json_field: json_string }
    res = Formatter::Substitution.substitute txt.dup, data:, tag_subs: nil
    expect(res).to eq "name: Alice\nscores:\n- 10\n- 20\n- 30\n"
  end

  it 'converts a YAML string field to JSON via parse_yaml and json formatters' do
    yaml_string = "name: Alice\nscores:\n- 10\n- 20\n- 30\n"
    txt = '{{yaml_field::parse_yaml::json}}'
    data = { yaml_field: yaml_string }
    res = Formatter::Substitution.substitute txt.dup, data:, tag_subs: nil
    expect(res).to eq "{\n  \"name\": \"Alice\",\n  \"scores\": [\n    10,\n    20,\n    30\n  ]\n}"
  end

  it 'returns nil representation when parse_json fails and is chained with a serializer' do
    txt = '{{json_field::parse_json::json}}'
    data = { json_field: 'not valid json' }
    res = Formatter::Substitution.substitute txt.dup, data:, tag_subs: nil
    expect(res).to eq 'null'
  end

  it 'parses a YAML encoded string using yaml_parse for hash key access' do
    txt = 'YAML {{yaml.yaml_parse.ykey2}}'
    data = { 'yaml' => "ykey1: 22\nykey2: abc\nykey3:\n- 1230\n- 4560\n" }
    res = Formatter::Substitution.substitute txt.dup, data:, tag_subs: nil
    expect(res).to eq 'YAML abc'
  end

  it 'parses a YAML encoded string using yaml_parse for array index access' do
    txt = 'YAML {{yaml.yaml_parse.ykey3.1}}'
    data = { 'yaml' => "ykey1: 22\nykey2: abc\nykey3:\n- 1230\n- 4560\n" }
    res = Formatter::Substitution.substitute txt.dup, data:, tag_subs: nil
    expect(res).to eq 'YAML 4560'
  end

  it 'indexes a top-level YAML array using yaml_parse with a numeric index' do
    txt = 'YAML {{yaml.yaml_parse.0}}'
    data = { 'yaml' => "- first\n- second\n- third\n" }
    res = Formatter::Substitution.substitute txt.dup, data:, tag_subs: nil
    expect(res).to eq 'YAML first'
  end

  it 'indexes a top-level YAML array using yaml_parse with first and last' do
    data = { 'yaml' => "- alpha\n- beta\n- gamma\n" }
    expect(Formatter::Substitution.substitute('{{yaml.yaml_parse.first}}', data:, tag_subs: nil)).to eq 'alpha'
    expect(Formatter::Substitution.substitute('{{yaml.yaml_parse.last}}', data:, tag_subs: nil)).to eq 'gamma'
  end

  it 'indexes a top-level JSON array using json_parse with a numeric index' do
    txt = 'JSON {{json.json_parse.0}}'
    data = { 'json' => '["first","second","third"]' }
    res = Formatter::Substitution.substitute txt.dup, data:, tag_subs: nil
    expect(res).to eq 'JSON first'
  end

  it 'indexes a top-level JSON array using json_parse with first and last' do
    data = { 'json' => '["alpha","beta","gamma"]' }
    expect(Formatter::Substitution.substitute('{{json.json_parse.first}}', data:, tag_subs: nil)).to eq 'alpha'
    expect(Formatter::Substitution.substitute('{{json.json_parse.last}}', data:, tag_subs: nil)).to eq 'gamma'
  end
end
