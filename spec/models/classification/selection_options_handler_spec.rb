# frozen_string_literal: true

require 'rails_helper'
AlNameGenTest = 'Gen Test ELT'

RSpec.describe Classification::SelectionOptionsHandler, type: :model do
  include ModelSupport
  include GeneralSelectionSupport

  before :context do
    SetupHelper.setup_al_gen_tests AlNameGenTest, 'elt', 'player_contact'
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

    ::ActivityLog.define_models
    @activity_log = al = ActivityLog.enabled.first

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
    ::ActivityLog.define_models

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
    ::ActivityLog.refresh_outdated
    al_def.reload
    al_def.force_option_config_parse

    Application.refresh_dynamic_defs

    expect(al_def.resource_name).to eq 'activity_log__player_contact_phones'

    setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
    setup_access :activity_log__player_contact_phone__step_1, resource_type: :activity_log_type, access: :create, user: @user
    ::ActivityLog.refresh_outdated

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
    ::ActivityLog.define_models

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

    ::ActivityLog.refresh_outdated unless al.extra_log_type_config
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
end
