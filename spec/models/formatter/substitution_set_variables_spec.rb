# frozen_string_literal: true

# Tests for the set_variables feature in option type configurations (issue #958).
#
# set_variables allows extra option or extra log type configurations to define
# an ordered list of variables with name, value (supporting substitutions),
# and optional conditional (if) logic. Variables are accessible through
# curly brace substitutions {{variables.varname}} or {{variables.hashvar.key1}},
# and via the element config in conditional calculations.
#
# These tests cover:
# - Basic variable substitution with {{variables.varname}}
# - Variables with substitution values (e.g. value: "{{some_field}}")
# - Conditional variables using the if form
# - Hash/object variable values with dot-notation access
# - Variable ordering (later entries override earlier ones for the same name)
# - Variables coexisting with existing _constants

require 'rails_helper'

RSpec.describe Formatter::Substitution, 'set_variables', type: :model do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport

  AlNameSetVarsTest = 'Set Variables Test ELT'

  before :context do
    SetupHelper.setup_al_gen_tests AlNameSetVarsTest, 'set_vars', 'player_contact'
  end

  before :example do
    @al_def = ActivityLog.active.where(name: AlNameSetVarsTest).first

    create_admin
    create_user
    create_master
    setup_access :player_infos, user: @user

    @player_info = @master.build_player_info(first_name: 'testfn', last_name: 'testln', birth_date: (Time.now - 30.years + 1.day))
    @player_info.force_save!
    @player_info.save!
    create_items

    let_user_create :player_contacts
    create_item
    @master.current_user = @user

    setup_access :activity_log__player_contact_set_vars, user: @user
  end

  def setup_activity_log_with_config(extra_log_types_yaml)
    @al_def.extra_log_types = extra_log_types_yaml
    @al_def.current_admin = @admin
    @al_def.save!

    setup_access :activity_log__player_contact_set_var__vars_step,
                 resource_type: :activity_log_type, access: :create, user: @user

    @al_def.reload

    @activity_log = @player_contact.activity_log__player_contact_set_vars.create!(
      select_call_direction: 'from player',
      select_who: 'user',
      master: @master,
      extra_log_type: 'vars_step'
    )
  end

  it 'substitutes basic set_variables values' do
    setup_activity_log_with_config(<<~YAML)
      vars_step:
        label: Vars Step
        set_variables:
          - name: greeting
            value: hello world
        caption_before:
          all_fields: '{{variables.greeting}}'
    YAML

    caption = @activity_log.extra_log_type_config.caption_before[:all_fields][:caption]
    res = Formatter::Substitution.substitute(caption, data: @activity_log, tag_subs: nil)

    expect(res).to eq '<p>hello world</p>'
  end

  it 'substitutes variables with embedded substitution values' do
    setup_activity_log_with_config(<<~YAML)
      vars_step:
        label: Vars Step
        set_variables:
          - name: user_greeting
            value: "hello {{select_who}}"
        caption_before:
          all_fields: '{{variables.user_greeting}}'
    YAML

    caption = @activity_log.extra_log_type_config.caption_before[:all_fields][:caption]
    res = Formatter::Substitution.substitute(caption, data: @activity_log, tag_subs: nil)

    expect(res).to eq '<p>hello user</p>'
  end

  it 'substitutes hash/object variables with dot-notation access' do
    setup_activity_log_with_config(<<~YAML)
      vars_step:
        label: Vars Step
        set_variables:
          - name: config
            value:
              object:
                key1: value1
                key2: value2
        caption_before:
          all_fields: '{{variables.config.key1}} and {{variables.config.key2}}'
    YAML

    caption = @activity_log.extra_log_type_config.caption_before[:all_fields][:caption]
    res = Formatter::Substitution.substitute(caption, data: @activity_log, tag_subs: nil)

    expect(res).to eq '<p>value1 and value2</p>'
  end

  it 'processes variables in order with later entries overriding earlier ones' do
    setup_activity_log_with_config(<<~YAML)
      vars_step:
        label: Vars Step
        set_variables:
          - name: status
            value: default status
          - name: status
            value: overridden status
        caption_before:
          all_fields: '{{variables.status}}'
    YAML

    caption = @activity_log.extra_log_type_config.caption_before[:all_fields][:caption]
    res = Formatter::Substitution.substitute(caption, data: @activity_log, tag_subs: nil)

    expect(res).to eq '<p>overridden status</p>'
  end

  it 'conditionally sets variables based on if conditions' do
    setup_activity_log_with_config(<<~YAML)
      vars_step:
        label: Vars Step
        set_variables:
          - name: result
            value: default result
          - name: result
            value: matched result
            if:
              all:
                this:
                  select_who: user
        caption_before:
          all_fields: '{{variables.result}}'
    YAML

    caption = @activity_log.extra_log_type_config.caption_before[:all_fields][:caption]
    res = Formatter::Substitution.substitute(caption, data: @activity_log, tag_subs: nil)

    expect(res).to eq '<p>matched result</p>'
  end

  it 'keeps earlier value when conditional does not match' do
    setup_activity_log_with_config(<<~YAML)
      vars_step:
        label: Vars Step
        set_variables:
          - name: result
            value: default result
          - name: result
            value: should not match
            if:
              all:
                this:
                  select_who: nonexistent_value
        caption_before:
          all_fields: '{{variables.result}}'
    YAML

    caption = @activity_log.extra_log_type_config.caption_before[:all_fields][:caption]
    res = Formatter::Substitution.substitute(caption, data: @activity_log, tag_subs: nil)

    expect(res).to eq '<p>default result</p>'
  end

  it 'works alongside existing _constants' do
    setup_activity_log_with_config(<<~YAML)
      _constants:
        fixed_val: constant value

      vars_step:
        label: Vars Step
        set_variables:
          - name: dynamic_val
            value: variable value
        caption_before:
          all_fields: '{{constants.fixed_val}} and {{variables.dynamic_val}}'
    YAML

    caption = @activity_log.extra_log_type_config.caption_before[:all_fields][:caption]
    res = Formatter::Substitution.substitute(caption, data: @activity_log, tag_subs: nil)

    expect(res).to eq '<p>constant value and variable value</p>'
  end

  it 'parses set_variables attribute on the option type config' do
    setup_activity_log_with_config(<<~YAML)
      vars_step:
        label: Vars Step
        set_variables:
          - name: test_var
            value: test_value
    YAML

    config = @activity_log.extra_log_type_config
    expect(config.set_variables).to be_an(Array)
    expect(config.set_variables.length).to eq 1
    expect(config.set_variables.first[:name]).to eq 'test_var'
    expect(config.set_variables.first[:value]).to eq 'test_value'
  end
end
