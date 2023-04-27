# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tracker, type: :model do
  include MasterSupport
  include ModelSupport
  before(:each) do
    create_user
    create_admin
    setup_access :trackers
    setup_access :tracker_history
    @p1 = Classification::Protocol.create name: 'P1', current_admin: @admin
    @p2 = Classification::Protocol.create name: 'P2', current_admin: @admin

    @sp1_1 = @p1.sub_processes.create name: 'SP1', current_admin: @admin
    @sp1_2 = @p1.sub_processes.create name: 'SP12', current_admin: @admin
    @sp2_1 = @p2.sub_processes.create name: 'SP2', current_admin: @admin

    @master = Master.new
    @master.current_user = @user
    @master.save!

    @tracker = @master.trackers.create protocol_id: @p1.id, sub_process_id: @sp1_1.id, event_date: DateTime.now
  end

  it 'allows trackers to be created for a master' do
    new_tracker = @master.trackers.create protocol_id: @p1.id, sub_process_id: @sp1_1.id, event_date: DateTime.now
    expect(new_tracker.save).to be true
  end

  it 'prevents trackers to be created outside of a master' do
    expect do
      Tracker.create protocol_id: @p1.id, sub_process_id: @sp1_1.id, user: @user, event_date: DateTime.now
    end.to raise_error 'can not set user='
  end

  it 'allows sub process changes after creation' do
    @tracker.sub_process = @sp1_2
    @tracker.event_date = DateTime.now
    expect(@tracker.save!).to be true
  end

  it 'prevents protocol change after creation' do
    @tracker.protocol = @p2

    @tracker.sub_process = @sp2_1

    expect(@tracker.save).to be false
  end

  it 'updates existing tracker record if attempting to insert with same protocol' do
    t2 = @master.trackers.build
    t2.protocol_id = @tracker.protocol_id
    t2.sub_process_id = @tracker.sub_process_id

    # Create an event to test with
    ev = @tracker.sub_process.protocol_events.create! name: 'event 1', current_admin: @admin

    expect(ev).to be_a Classification::ProtocolEvent
    expect(ev).to be_persisted

    t2.protocol_event_id = ev.id
    t2.event_date = DateTime.now

    tres = t2.merge_if_exists

    expect(tres.merge_if_exists).to be_a(Tracker), "Tracker duplicate didn't save: #{t2.errors.inspect}"
    expect(tres._merged).to be true
    expect(tres.id).to eq @tracker.id
  end

  it 'gets completions' do
    setup_access :tracker_histories

    master = create_master

    Admin::AppConfiguration.add_default_config(@user.app_type, :completion_sub_processes, "#{@sp1_1.id}, #{@sp1_2.id}", @admin)

    res = master.tracker_completions
    expect(res.length).to eq 0

    t2 = master.trackers.build
    t2.protocol_id = @sp1_1.protocol_id
    t2.sub_process_id = @sp1_1.id
    t2.event_date = DateTime.now
    t2.save!

    res = master.tracker_completions
    expect(res.length).to eq 1

    # TODO: why a string instead of a symbol
    res = master.as_json['tracker_completions'].first['sub_process_name']
    expect(res).to eq @sp1_1.name
  end
end
