# frozen_string_literal: true

require 'rails_helper'

AlNameGenTestMr = 'Gen Test ELT'
# Use the activity log player contact phone activity log implementation,
# since it includes the works_with concern

RSpec.describe 'Model references', type: :model do
  def al_name
    AlNameGenTestMr
  end

  include ActivityLogSupport
  include ModelSupport
  include PlayerContactSupport

  before :context do
    SetupHelper.setup_al_gen_tests AlNameGenTestMr, 'elt', 'player_contact'
  end

  before :each do
    create_admin
    create_user
    setup_access :player_contacts
    setup_access :addresses
    setup_access :activity_log__player_contact_phones
    @player_contact1 = create_item(data: rand(10_000_000_000_000_000), rank: 10)
    @player_contact2 = create_item({ data: rand(10_000_000_000_000_000), rank: 10 }, @master)
    @player_contact3 = create_item({ data: rand(10_000_000_000_000_000), rank: 10 }, @master)

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
          address:
            from: this
            add: many
            also_disable_record: true

    END_DEF

    al.current_admin = @admin
    al.save!
    al = @activity_log
    setup_access al.resource_name, resource_type: :table, user: @user

    setup_option_config 0, 'Step 1', %w[select_call_direction select_who]
    setup_option_config 1, 'Step 2', %w[select_call_direction select_who]
    setup_option_config 2, 'Reference Simple Test', %w[select_call_direction select_who]

    @address = @master.addresses.create!(
      street: '123 main',
      city: 'dallas',
      state: 'tx',
      zip: '81262',
      rank: 10
    )
  end

  it 'creates a model reference record from a master record' do
    @player_contact.current_user = @user
    al_simple = @player_contact.activity_log__player_contact_elts.build(select_call_direction: 'from staff',
                                                                        extra_log_type: 'mr_simple_test',
                                                                        select_who: 'abc')
    al_simple.save!

    mr = ModelReference.create_from_master_with(al_simple.master, @player_contact)
    expect(ModelReference.last).to eq mr
    expect(al_simple.model_references.first).to eq mr

    expect(mr.attributes.symbolize_keys.slice(:from_record_master_id, :from_record_id, :from_record_type)).to eq(
      from_record_master_id: @master.id,
      from_record_id: nil,
      from_record_type: nil
    )

    expect(mr.attributes.symbolize_keys.slice(:to_record_master_id, :to_record_id, :to_record_type)).to eq(
      to_record_master_id: @master.id,
      to_record_id: @player_contact.id,
      to_record_type: 'PlayerContact'
    )
  end

  it 'creates a model reference record from a model' do
    @player_contact.current_user = @user
    al_simple = @player_contact.activity_log__player_contact_elts.build(select_call_direction: 'from staff',
                                                                        extra_log_type: 'mr_simple_test',
                                                                        select_who: 'abc')
    al_simple.save!

    mr = ModelReference.create_with(al_simple, @address)
    expect(ModelReference.last).to eq mr
    expect(al_simple.model_references.first).to eq mr

    expect(mr.attributes.symbolize_keys.slice(:from_record_master_id, :from_record_id, :from_record_type)).to eq(
      from_record_master_id: @master.id,
      from_record_id: al_simple.id,
      from_record_type: 'ActivityLog::PlayerContactElt'
    )

    expect(mr.attributes.symbolize_keys.slice(:to_record_master_id, :to_record_id, :to_record_type)).to eq(
      to_record_master_id: @master.id,
      to_record_id: @address.id,
      to_record_type: 'Address'
    )
  end

  it 'creates a multiple model reference records' do
    @player_contact.current_user = @user
    al_simple = @player_contact.activity_log__player_contact_elts.build(select_call_direction: 'from staff',
                                                                        extra_log_type: 'mr_simple_test',
                                                                        select_who: 'abc')
    al_simple.save!

    mr = ModelReference.create_from_master_with(al_simple.master, @player_contact)
    expect(ModelReference.last).to eq mr
    expect(al_simple.model_references.first).to eq mr

    mr = ModelReference.create_with(al_simple, @address)
    expect(ModelReference.last).to eq mr
    # The model references are memoized in the instance. Adding a reference to a model instance does force
    # the cache to be refreshed
    expect(al_simple.model_references.first).to eq mr
    expect(al_simple.model_references.length).to eq 2

    mr = ModelReference.create_from_master_with(al_simple.master, @player_contact1)
    expect(ModelReference.last).to eq mr
    # The model references are memoized in the instance. Adding a reference to a master does not reset the
    # cached values, so the #model_references call will not show the latest item
    # Model references are returned grouped by model reference definition
    # Therefore we have just added a new reference to the second group
    expect(al_simple.model_references.length).to eq 2
    # To handle this, the consumer must force a reload
    al_simple.reset_model_references
    expect(al_simple.model_references.length).to eq 3
    expect(al_simple.model_references.select { |m| m.to_record_type == 'PlayerContact' }.first).to eq mr
  end
end
