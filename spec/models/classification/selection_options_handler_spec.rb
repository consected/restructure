# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Classification::SelectionOptionsHandler, type: :model do
  AlNameGenTestSo = 'Gen Test ELT'
  include ModelSupport
  include GeneralSelectionSupport

  before :context do
    SetupHelper.setup_al_gen_tests AlNameGenTestSo, 'elt', 'player_contact'
  end

  before :example do
    create_admin
    create_user
    setup_access :player_contacts

    create_master
    create_items :list_valid_attribs
  end

  it 'overrides general selection configurations with dynamic model alt_options' do
    config0 = Classification::SelectionOptionsHandler.selector_with_config_overrides

    ActivityLog.define_models
    @activity_log = al = ActivityLog::PlayerContactPhone.definition

    cleanup_matching_activity_logs(al.item_type, al.rec_type, al.process_name, excluding_id: al.id)

    al.extra_log_types = <<~END_DEF
      step_1:
        label: Step 1
        fields:
          - select_call_direction
          - select_who

        field_options:
          select_call_direction:
            edit_as:
              alt_options:
                This is one: one
                This is two: two
                This is nine: nine

      step_2:
        label: Step 2
        fields:
          - select_call_direction
          - extra_text
    END_DEF

    al.current_admin = @admin
    al.save!

    dm = DynamicModel.implementation_classes.first

    config1 = Classification::SelectionOptionsHandler.selector_with_config_overrides item_type: dm.new.item_type
    expect(config0.length).not_to eq config1.length
    config2 = Classification::SelectionOptionsHandler.selector_with_config_overrides extra_log_type: 'step_1', item_type: al.resource_name.singularize
    expect(config2.length).not_to eq config1.length

    results = [
      { id: 4, item_type: 'activity_log__player_contact_phone_select_next_step', value: 'call back', name: 'Call Back', create_with: true, edit_if_set: nil, position: nil, lock: true },
      { id: 3, item_type: 'activity_log__player_contact_phone_select_next_step', value: 'complete', name: 'Complete', create_with: true, edit_if_set: nil, position: nil, lock: true },
      { id: 6, item_type: 'activity_log__player_contact_phone_select_next_step', value: 'more info requested', name: 'More Info Requested', create_with: true, edit_if_set: nil, position: nil, lock: true },
      { id: 5, item_type: 'activity_log__player_contact_phone_select_next_step', value: 'no follow up', name: 'No Follow Up', create_with: true, edit_if_set: nil, position: nil, lock: true },
      { id: 10, item_type: 'activity_log__player_contact_phone_select_result', value: 'bad number', name: 'Bad Number', create_with: true, edit_if_set: nil, position: nil, lock: true },
      { id: 7, item_type: 'activity_log__player_contact_phone_select_result', value: 'connected', name: 'Connected', create_with: true, edit_if_set: nil, position: nil, lock: true },
      { id: 8, item_type: 'activity_log__player_contact_phone_select_result', value: 'voicemail', name: 'Left Voicemail', create_with: true, edit_if_set: nil, position: nil, lock: true },
      { id: 9, item_type: 'activity_log__player_contact_phone_select_result', value: 'not connected', name: 'Not Connected', create_with: true, edit_if_set: nil, position: nil, lock: true },
      { id: 11, item_type: 'activity_log__player_contact_phone_select_who', value: 'user', name: 'User', create_with: true, edit_if_set: nil, position: nil, lock: true },
      { id: nil, item_type: 'activity_log__player_contact_phone_select_call_direction', value: 'one', name: 'This is one', create_with: nil, edit_if_set: nil, lock: nil },
      { id: nil, item_type: 'activity_log__player_contact_phone_select_call_direction', value: 'two', name: 'This is two', create_with: nil, edit_if_set: nil, lock: nil },
      { id: nil, item_type: 'activity_log__player_contact_phone_select_call_direction', value: 'nine', name: 'This is nine', create_with: nil, edit_if_set: nil, lock: nil }
    ]

    results.each { |r| r.delete :id }

    config2_sliced = config2.map { |c| c.slice :item_type, :value, :name, :create_with, :edit_if_set, :position, :lock }
    expect(config2_sliced).to eq results
  end

  it 'substitutes labels into data attributes for dynamic defintions' do
    ActivityLog.define_models

    @master.current_user = @user
    player_contact = @master.player_contacts.create(rec_type: :phone, data: '(123) 456-7890')

    al_def = ActivityLog::PlayerContactPhone.definition
    cleanup_matching_activity_logs(al_def.item_type, al_def.rec_type, al_def.process_name, excluding_id: al_def.id)

    sleep 1
    al_def.extra_log_types = <<~END_DEF
      # Ensure the new def saves: #{SecureRandom.hex(10)}
      step_1:
        label: Step 1
        fields:
          - select_call_direction
          - select_who

        view_options:
          data_attribute: '{{id}} - {{select_call_direction}}'

        field_options:
          select_call_direction:
            edit_as:
              alt_options:
                This is one: one
                This is two: two
                This is nine: nine
    END_DEF

    al_def.current_admin = @admin
    al_def.force_regenerate = true
    al_def.updated_at = DateTime.now # force a save
    al_def.save!
    ActivityLog.refresh_outdated
    al_def.reload
    al_def.force_option_config_parse

    Application.refresh_dynamic_defs

    expect(al_def.resource_name).to eq 'activity_log__player_contact_phones'

    setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
    setup_access :activity_log__player_contact_phone__step_1, resource_type: :activity_log_type, access: :create, user: @user
    ActivityLog.refresh_outdated

    sleep 2
    al = player_contact.activity_log__player_contact_phones.build(select_call_direction: 'one',
                                                                  select_who: 'user',
                                                                  extra_log_type: 'step_1')

    expect(al.class.definition).to eq al_def

    expect(al_def.disabled).to be_falsey
    al_def.option_configs force: false unless al.extra_log_type_config
    expect(al.extra_log_type_config).not_to be nil
    al.save!
    al.data
    expect(al.data).to eq "#{al.id} - #{al.select_call_direction}"
  end

  it 'gets labels for specific model, field name and value' do
    ActivityLog.define_models

    @master.current_user = @user
    player_contact = @master.player_contacts.create(rec_type: :phone, data: '(123) 456-7890')

    al_def = ActivityLog::PlayerContactPhone.definition
    cleanup_matching_activity_logs(al_def.item_type, al_def.rec_type, al_def.process_name, excluding_id: al_def.id)

    al_def.extra_log_types = <<~END_DEF
      step_1:
        label: Step 1
        fields:
          - select_call_direction
          - select_who
          - select_result

        view_options:
          data_attribute: '{{id}} - {{select_call_direction}}'

        field_options:
          select_call_direction:
            edit_as:
              alt_options:
                This is one: one
                This is two: two
                This is nine: nine
    END_DEF

    al_def.current_admin = @admin
    al_def.save!
    al_def.force_option_config_parse

    expect(al_def.resource_name).to eq 'activity_log__player_contact_phones'

    setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
    setup_access :activity_log__player_contact_phone__step_1, resource_type: :activity_log_type, user: @user

    expect(player_contact.current_user).to eq @user
    sleep 2
    al = player_contact.activity_log__player_contact_phones.build(select_call_direction: 'from player',
                                                                  select_who: 'user',
                                                                  extra_log_type: 'step_1')

    ActivityLog.refresh_outdated unless al.extra_log_type_config
    expect(al.extra_log_type_config).not_to be nil
    al.save!

    res = Classification::SelectionOptionsHandler.label_for(al, :select_call_direction, 'two')
    expect(res).to eq 'This is two'

    so = Classification::SelectionOptionsHandler.new(user_base_object: al)

    res = so.label_for(:select_call_direction, 'nine')
    expect(res).to eq 'This is nine'

    res = so.label_for(:select_who, 'user')
    expect(res).to eq 'User'

    # Test with a table name as a setup
    so = Classification::SelectionOptionsHandler.new(table_name: :activity_log_player_contact_phones)
    res = so.label_for(:select_result, 'voicemail')
    expect(res).to eq 'Left Voicemail'
  end

  it 'gets labels for select_from field' do
    ActivityLog.define_models

    @master.current_user = @user
    setup_access :player_contacts, user: @user

    player_contact = @master.player_contacts.create!(rec_type: :phone, data: '(123) 456-7890', rank: 10)
    @master.player_contacts.create!(rec_type: :phone, data: '(123) 456-7891', rank: 5)
    player_contact3 = @master.player_contacts.create!(rec_type: :phone, data: '(123) 456-7892', rank: 5)

    pc_data = "#{player_contact.data} [primary]"
    pc_data3 = "#{player_contact3.data} [secondary]"

    create_item name: 'User',
                value: 'user',
                item_type: 'activity_log__player_contact_elt_select_who',
                disabled: false

    create_item name: 'User 1',
                value: 'user 1',
                item_type: 'activity_log__player_contact_elt_select_who',
                disabled: false

    al_def = ActivityLog::PlayerContactElt.definition
    cleanup_matching_activity_logs(al_def.item_type, al_def.rec_type, al_def.process_name, excluding_id: al_def.id)

    al_def.extra_log_types = <<~END_DEF
      step_3:
        label: Step 3
        fields:
          - select_call_direction
          - select_who
          - select_result
          - select_record_id_from_player_contacts
          - tag_select_allowed
          - tag_select_record_id_from_player_contacts


        view_options:
          data_attribute: '{{id}} - {{select_call_direction}}'

        field_options:
          tag_select_allowed:
            edit_as:
              alt_options:
                This ABC: abc
                This DEF: def
                This GHI: ghi
          select_call_direction:
            edit_as:
              alt_options:
                This is one: one
                This is two: two
                This is nine: nine
    END_DEF

    al_def.current_admin = @admin
    al_def.save!
    al_def.force_option_config_parse

    expect(al_def.resource_name).to eq 'activity_log__player_contact_elts'

    setup_access :activity_log__player_contact_elts, resource_type: :table, access: :create, user: @user
    setup_access :activity_log__player_contact_elt__step_3, resource_type: :activity_log_type, user: @user

    expect(player_contact.current_user).to eq @user
    expect(player_contact.current_user.has_access_to?(:create, :activity_log_type, :activity_log__player_contact_elt__step_3))
    sleep 2
    al = player_contact.activity_log__player_contact_elts.create!(select_call_direction: 'one',
                                                                  select_who: 'user',
                                                                  extra_log_type: 'step_3',
                                                                  select_record_id_from_player_contacts: player_contact.id,
                                                                  tag_select_allowed: ['def', 'ghi'],
                                                                  tag_select_record_id_from_player_contacts: [player_contact.id, player_contact3.id])

    ActivityLog.refresh_outdated unless al.extra_log_type_config
    expect(al.extra_log_type_config).not_to be nil
    al.save!

    res = Classification::SelectionOptionsHandler.label_for(al, :select_record_id_from_player_contacts, player_contact.id.to_s)
    expect(res).to eq pc_data

    res = Classification::SelectionOptionsHandler.label_for(al, :tag_select_allowed, 'def')
    expect(res).to eq 'This DEF'
    res = Classification::SelectionOptionsHandler.label_for(al, :tag_select_allowed, 'ghi')
    expect(res).to eq 'This GHI'

    res = Classification::SelectionOptionsHandler.label_for(al, :tag_select_record_id_from_player_contacts, player_contact.id)
    expect(res).to eq pc_data

    res = Classification::SelectionOptionsHandler.label_for(al, :tag_select_record_id_from_player_contacts, player_contact3.id)
    expect(res).to eq pc_data3

    algs = {
      'select_call_direction' => {
        'one' => { name: 'This is one' }
      },
      'select_next_step' => {},
      'select_who' => {
        'user' => { name: 'User' }
      },
      'select_result' => {},
      'select_record_id_from_player_contacts' => {
        player_contact.id.to_s => { name: pc_data }
      },
      'tag_select_allowed' => {
        'def' => { name: 'This DEF' },
        'ghi' => { name: 'This GHI' }
      },
      'tag_select_record_id_from_player_contacts' => {
        player_contact.id.to_s => { name: pc_data },
        player_contact3.id.to_s => { name: pc_data3 }
      }
    }

    al._general_selections
    expect(al._general_selections).to eq algs
  end

  it 'gets labels for redcap select fields' do
    ActivityLog.define_models

    @master.current_user = @user
    setup_access :player_contacts, user: @user

    player_contact = @master.player_contacts.create!(rec_type: :phone, data: '(123) 456-7890', rank: 10)
    @master.player_contacts.create!(rec_type: :phone, data: '(123) 456-7891', rank: 5)
    player_contact3 = @master.player_contacts.create!(rec_type: :phone, data: '(123) 456-7892', rank: 5)

    pc_data = "#{player_contact.data} [primary]"
    pc_data3 = "#{player_contact3.data} [secondary]"

    create_item name: 'User',
                value: 'user',
                item_type: 'activity_log__player_contact_elt_select_who',
                disabled: false

    create_item name: 'User 1',
                value: 'user 1',
                item_type: 'activity_log__player_contact_elt_select_who',
                disabled: false

    al_def = ActivityLog::PlayerContactElt.definition
    cleanup_matching_activity_logs(al_def.item_type, al_def.rec_type, al_def.process_name, excluding_id: al_def.id)

    al_def.extra_log_types = <<~END_DEF
      step_3:
        label: Step 3
        fields:
          - select_call_direction
          - select_who
          - select_result
          - select_record_id_from_player_contacts
          - tag_select_allowed
          - tag_select_record_id_from_player_contacts


        view_options:
          data_attribute: '{{id}} - {{select_call_direction}}'

        field_options:
          tag_select_allowed:
            edit_as:
              field_type: redcap_tag_select
              alt_options:
                This rcABC: rcabc
                This rcDEF: rcdef
                This rcGHI: rcghi
          select_call_direction:
            edit_as:
              field_type: redcap_select
              alt_options:
                This is rcone: rcone
                This is rctwo: rctwo
                This is rcnine: rcnine
          select_result:
            edit_as:
              field_type: redcap_radio
              alt_options:
                Radio one: r-one
                Radio two: r-two

    END_DEF

    al_def.current_admin = @admin
    al_def.save!
    al_def.force_option_config_parse

    expect(al_def.resource_name).to eq 'activity_log__player_contact_elts'

    setup_access :activity_log__player_contact_elts, resource_type: :table, access: :create, user: @user
    setup_access :activity_log__player_contact_elt__step_3, resource_type: :activity_log_type, user: @user

    expect(player_contact.current_user).to eq @user
    sleep 2
    al = player_contact.activity_log__player_contact_elts.create!(select_call_direction: 'rcone',
                                                                  select_who: 'user',
                                                                  extra_log_type: 'step_3',
                                                                  select_record_id_from_player_contacts: player_contact.id,
                                                                  tag_select_allowed: ['rcdef', 'rcghi'],
                                                                  tag_select_record_id_from_player_contacts: [player_contact.id, player_contact3.id],
                                                                  select_result: 'r-two')

    ActivityLog.refresh_outdated unless al.extra_log_type_config
    expect(al.extra_log_type_config).not_to be nil
    al.save!

    res = Classification::SelectionOptionsHandler.label_for(al, :select_record_id_from_player_contacts, player_contact.id.to_s)
    expect(res).to eq pc_data

    res = Classification::SelectionOptionsHandler.label_for(al, :tag_select_allowed, 'rcdef')
    expect(res).to eq 'This rcDEF'
    res = Classification::SelectionOptionsHandler.label_for(al, :tag_select_allowed, 'rcghi')
    expect(res).to eq 'This rcGHI'

    res = Classification::SelectionOptionsHandler.label_for(al, :tag_select_record_id_from_player_contacts, player_contact.id)
    expect(res).to eq pc_data

    res = Classification::SelectionOptionsHandler.label_for(al, :tag_select_record_id_from_player_contacts, player_contact3.id)
    expect(res).to eq pc_data3

    algs = {
      'select_call_direction' => {
        'rcone' => { name: 'This is rcone' }
      },
      'select_next_step' => {},
      'select_who' => {
        'user' => { name: 'User' }
      },
      'select_result' => {
        'r-two' => { name: 'Radio two' }
      },
      'select_record_id_from_player_contacts' => {
        player_contact.id.to_s => { name: pc_data }
      },
      'tag_select_allowed' => {
        'rcdef' => { name: 'This rcDEF' },
        'rcghi' => { name: 'This rcGHI' }
      },
      'tag_select_record_id_from_player_contacts' => {
        player_contact.id.to_s => { name: pc_data },
        player_contact3.id.to_s => { name: pc_data3 }
      }
    }

    al._general_selections
    expect(al._general_selections).to eq algs
  end

  # Tests for select_user_with_role_ field type (Issue #333)
  # The select_user_with_role_ field type sources options from Admin::UserRole,
  # fetching active, non-template users with a specific role.
  # These tests verify label_for, selector_with_config_overrides, and _general_selections
  # return correct data for select_user_with_role_ fields.

  it 'gets labels for select_user_with_role field' do
    ActivityLog.define_models

    @master.current_user = @user
    setup_access :player_contacts, user: @user

    player_contact = @master.player_contacts.create!(rec_type: :phone, data: '(123) 456-7890', rank: 10)

    create_item name: 'User',
                value: 'user',
                item_type: 'activity_log__player_contact_elt_select_who',
                disabled: false

    # Create an additional user and assign a role to them
    role_name = 'test reviewer'
    original_user = @user
    role_user, = create_user('role-user-333')
    create_user_role(role_name, user: role_user, app_type: role_user.app_type)
    @user = original_user

    al_def = ActivityLog::PlayerContactElt.definition
    cleanup_matching_activity_logs(al_def.item_type, al_def.rec_type, al_def.process_name, excluding_id: al_def.id)

    al_def.extra_log_types = <<~END_DEF
      step_user_role:
        label: Step User Role
        fields:
          - select_call_direction
          - select_who
          - select_result

        field_options:
          select_who:
            edit_as:
              field_type: select_user_with_role_test_reviewer
              label_attr: first_name
          select_call_direction:
            edit_as:
              alt_options:
                This is one: one
                This is two: two
    END_DEF

    al_def.current_admin = @admin
    al_def.save!
    al_def.force_option_config_parse

    setup_access :activity_log__player_contact_elts, resource_type: :table, access: :create, user: @user
    setup_access :activity_log__player_contact_elt__step_user_role, resource_type: :activity_log_type, user: @user

    expect(player_contact.current_user).to eq @user
    sleep 2
    al = player_contact.activity_log__player_contact_elts.create!(select_call_direction: 'one',
                                                                  select_who: role_user.email,
                                                                  extra_log_type: 'step_user_role')

    ActivityLog.refresh_outdated unless al.extra_log_type_config
    expect(al.extra_log_type_config).not_to be nil
    al.save!

    # label_for should return the user's first_name as the label for a select_user_with_role_ field
    # when label_attr is configured as first_name and value_attr defaults to email.
    res = Classification::SelectionOptionsHandler.label_for(al, :select_who, role_user.email)
    expect(res).to eq role_user.first_name
  end

  it 'includes select_user_with_role options in selector_with_config_overrides' do
    ActivityLog.define_models

    @master.current_user = @user
    setup_access :player_contacts, user: @user

    @master.player_contacts.create!(rec_type: :phone, data: '(123) 456-7890', rank: 10)

    create_item name: 'User',
                value: 'user',
                item_type: 'activity_log__player_contact_elt_select_who',
                disabled: false

    # Create an additional user and assign a role to them
    role_name = 'test reviewer'
    original_user = @user
    role_user, = create_user('role-user-swco-333')
    create_user_role(role_name, user: role_user, app_type: role_user.app_type)
    @user = original_user

    al_def = ActivityLog::PlayerContactElt.definition
    cleanup_matching_activity_logs(al_def.item_type, al_def.rec_type, al_def.process_name, excluding_id: al_def.id)

    al_def.extra_log_types = <<~END_DEF
      step_user_role:
        label: Step User Role
        fields:
          - select_call_direction
          - select_who

        field_options:
          select_who:
            edit_as:
              field_type: select_user_with_role_test_reviewer
          select_call_direction:
            edit_as:
              alt_options:
                This is one: one
    END_DEF

    al_def.current_admin = @admin
    al_def.save!
    al_def.force_option_config_parse

    setup_access :activity_log__player_contact_elts, resource_type: :table, access: :create, user: @user
    setup_access :activity_log__player_contact_elt__step_user_role, resource_type: :activity_log_type, user: @user

    Classification::SelectionOptionsHandler.reset!

    config = Classification::SelectionOptionsHandler.selector_with_config_overrides(
      extra_log_type: 'step_user_role',
      item_type: al_def.resource_name.singularize
    )

    # selector_with_config_overrides should include entries for the select_user_with_role_ field
    select_who_entries = config.select { |c| c[:field_name] == :select_who }
    expect(select_who_entries).not_to be_empty

    role_user_entry = select_who_entries.find { |c| c[:value] == role_user.email }
    expect(role_user_entry).not_to be_nil
    expect(role_user_entry[:name]).to eq role_user.email
  end

  it 'includes select_user_with_role values in _general_selections' do
    ActivityLog.define_models

    @master.current_user = @user
    setup_access :player_contacts, user: @user

    player_contact = @master.player_contacts.create!(rec_type: :phone, data: '(123) 456-7890', rank: 10)

    create_item name: 'User',
                value: 'user',
                item_type: 'activity_log__player_contact_elt_select_who',
                disabled: false

    # Create an additional user and assign a role to them
    role_name = 'test reviewer'
    original_user = @user
    role_user, = create_user('role-user-gs-333')
    create_user_role(role_name, user: role_user, app_type: role_user.app_type)
    @user = original_user

    al_def = ActivityLog::PlayerContactElt.definition
    cleanup_matching_activity_logs(al_def.item_type, al_def.rec_type, al_def.process_name, excluding_id: al_def.id)

    al_def.extra_log_types = <<~END_DEF
      step_user_role:
        label: Step User Role
        fields:
          - select_call_direction
          - select_who

        field_options:
          select_who:
            edit_as:
              field_type: select_user_with_role_test_reviewer
          select_call_direction:
            edit_as:
              alt_options:
                This is one: one
    END_DEF

    al_def.current_admin = @admin
    al_def.save!
    al_def.force_option_config_parse

    setup_access :activity_log__player_contact_elts, resource_type: :table, access: :create, user: @user
    setup_access :activity_log__player_contact_elt__step_user_role, resource_type: :activity_log_type, user: @user

    expect(player_contact.current_user).to eq @user
    sleep 2
    al = player_contact.activity_log__player_contact_elts.create!(select_call_direction: 'one',
                                                                  select_who: role_user.email,
                                                                  extra_log_type: 'step_user_role')

    ActivityLog.refresh_outdated unless al.extra_log_type_config
    expect(al.extra_log_type_config).not_to be nil
    al.save!

    # _general_selections should include the role user's email as the label for the select_who field
    gs = al._general_selections
    expect(gs['select_who']).to be_present
    expect(gs['select_who'][role_user.email]).to eq({ name: role_user.email })
  end
end
