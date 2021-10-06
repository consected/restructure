# frozen_string_literal: true

require 'rails_helper'

AlNameGenTest = 'Gen Test ELT'
# Use the activity log player contact phone activity log implementation,
# since it includes the works_with concern

RSpec.describe 'Activity Log extra types implementation', type: :model do
  def al_name
    AlNameGenTest
  end

  include ModelSupport
  include PlayerContactSupport

  before :context do
    SetupHelper.setup_al_gen_tests AlNameGenTest, 'elt', 'player_contact'
  end

  before :each do
    create_admin
    create_user
    setup_access :player_contacts
    setup_access :activity_log__player_contact_phones
    create_item(data: rand(10_000_000_000_000_000), rank: 10)

    @activity_log = al = ActivityLog.active.where(name: al_name).first
    @working_data = '(111)222-3333 ext 7654321'

    raise "Activity Log #{al_name} not set up" if al.nil?

    al.extra_log_types = <<~END_DEF
      step_1:
        label: Step 1
        fields:
          - select_call_direction
          - select_who

      step_2:
        label: Step 2
        fields:
          - select_call_direction
          - select_who


      mr_simple_test:
        label: Reference Simple Test
        fields:
          - select_call_direction
          - select_who
        references:
          player_contacts:
            from: master
            add: many

      mr_showable_test:
        label: Reference Showable Test
        fields:
          - select_call_direction
          - select_who
        references:
          player_contacts:
            from: master
            add: many
            showable_if:
              all:
                this:
                  select_who: 'xyz'
                reference:
                  data: '#{@working_data}'


      mr_self_ref:
        label: Reference Self Test
        fields:
          - select_call_direction
          - select_who
          - disabled
        editable_if:
          always: true
        references:
          player_contacts:
            from: master
            add: many
          activity_log__player_contact_elt:
            from: this
            add: many
            also_disable_record: true

    END_DEF

    al.current_admin = @admin

    al.save!

    al = @activity_log

    c1 = al.option_configs.first
    expect(c1.label).to eq 'Step 1'
    expect(c1.fields).to eq %w[select_call_direction select_who]

    c3 = al.option_configs[2]
    expect(c3.label).to eq 'Reference Simple Test'
    expect(c3.fields).to eq %w[select_call_direction select_who]

    c4 = al.option_configs[3]
    expect(c4.label).to eq 'Reference Showable Test'
    expect(c4.fields).to eq %w[select_call_direction select_who]

    c5 = al.option_configs[4]
    expect(c5.label).to eq 'Reference Self Test'
    expect(c5.fields).to eq %w[select_call_direction select_who disabled]

    setup_access al.resource_name, resource_type: :table, user: @user
    setup_access c3.resource_name, resource_type: :activity_log_type, user: @user
    setup_access c4.resource_name, resource_type: :activity_log_type, user: @user
    setup_access c5.resource_name, resource_type: :activity_log_type, user: @user
  end

  it 'saves data into an activity log record' do
    puts @activity_log.resource_name

    @player_contact.current_user = @user

    al_simple = @player_contact.activity_log__player_contact_elts.build(select_call_direction: 'from staff',
                                                                        extra_log_type: 'mr_simple_test',
                                                                        select_who: 'abc')
    al_simple.save!

    ModelReference.create_from_master_with(al_simple.master, @player_contact)

    al_showable = @player_contact.activity_log__player_contact_elts.build(select_call_direction: 'from staff',
                                                                          extra_log_type: 'mr_showable_test',
                                                                          select_who: 'xyz')
    al_showable.save!

    master = al_showable.master

    # Simple always works
    expect(al_simple.model_references.length).to be > 0
    # Showable doesn't work initially because the reference data does not match
    expect(al_showable.model_references.length).to eq 0

    # Requires the to record to have data: (111)...
    att = {
      data: @working_data,
      rec_type: 'phone',
      source: 'nfl',
      rank: 10
    }
    pc2 = create_item(att, master)
    ModelReference.create_from_master_with(master, pc2)

    # Showable should now work, since the current record matches on select_who, and the reference matches on data

    al_showable.reference = pc2
    ref_config = al_showable.extra_log_type_config.references.first.last[:player_contact]
    res = al_showable.extra_log_type_config.calc_reference_if(ref_config, :showable_if, al_showable, default_if_no_config: true)
    expect(res).to be_truthy

    al_showable.reset_model_references
    expect(al_showable.model_references.length).to eq 1
    expect(al_simple.model_references.length).to be > 0

    # Showable should now not work, since the current record does not match on select_who,
    # even though the reference matches on data
    al_showable.update! select_who: 'ghi'
    al_showable.reset_model_references
    expect(al_showable.model_references.length).to eq 0
    expect(al_simple.model_references.length).to be > 0
  end

  it 'handles disabling of references and referenced items' do
    puts @activity_log.resource_name

    @player_contact.current_user = @user
    @player_contact.master.current_user = @user

    referenced = @player_contact.activity_log__player_contact_elts.create!(select_call_direction: 'from staff',
                                                                           extra_log_type: 'mr_self_ref',
                                                                           select_who: 'abc',
                                                                           master: @player_contact.master)

    referenced2 = @player_contact.activity_log__player_contact_elts.create!(select_call_direction: 'from staff',
                                                                            extra_log_type: 'mr_self_ref',
                                                                            select_who: 'abc2',
                                                                            master: @player_contact.master)

    al_simple = @player_contact.activity_log__player_contact_elts.build(select_call_direction: 'from staff',
                                                                        extra_log_type: 'mr_self_ref',
                                                                        select_who: 'abc')
    al_simple.save!

    mr = ModelReference.create_from_master_with(al_simple.master, @player_contact)

    mr_ref = ModelReference.create_with(al_simple, referenced)
    mr_ref2 = ModelReference.create_with(al_simple, referenced2)

    expect(al_simple.model_references.length).to be > 0

    # Disabling a reference pointing to a record with no disabled field should work
    mr.update!(disabled: true)
    expect(mr.disabled).to be true

    # Disabling a reference having the option also_disable_record also disables the to_record
    mr_ref.update!(disabled: true)
    expect(mr_ref.disabled).to be true
    referenced.reload
    expect(referenced.disabled).to be true

    # Disabling the to_record should lead to the model reference records pointing to it being disabled
    referenced2.update!(disabled: true, current_user: @user)
    referenced2.reload
    mr_ref2.reload
    expect(referenced2.disabled).to be true
    expect(mr_ref2.disabled).to be true
  end
end
