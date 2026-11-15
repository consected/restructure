# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tracker, type: :model do
  include MasterSupport
  include ModelSupport
  before(:each) do
    create_user
    create_admin
    setup_access :trackers
    setup_access :tracker_histories
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

  describe 'tracker_histories association' do
    it 'orders tracker histories by event_date::date DESC, then id DESC' do
      master = create_master
      
      # Create multiple tracker entries to test the ordering
      # Day 1: Two entries on the same date (different times)
      day1_time1 = 3.days.ago.beginning_of_day + 9.hours
      day1_time2 = 3.days.ago.beginning_of_day + 14.hours
      
      tracker1 = master.trackers.create!(
        protocol_id: @p1.id,
        sub_process_id: @sp1_1.id,
        event_date: day1_time1,
        notes: 'Day 1 - Morning'
      )
      
      tracker2 = master.trackers.create!(
        protocol_id: @p1.id,
        sub_process_id: @sp1_1.id,
        event_date: day1_time2,
        notes: 'Day 1 - Afternoon'
      )
      
      # Day 2: One entry (most recent date)
      tracker3 = master.trackers.create!(
        protocol_id: @p1.id,
        sub_process_id: @sp1_1.id,
        event_date: 1.day.ago.beginning_of_day + 10.hours,
        notes: 'Day 2 - Single'
      )
      
      # Get tracker histories via the association
      histories = master.tracker_histories.to_a
      
      expect(histories.length).to be >= 3
      
      # Find our test histories
      our_histories = histories.select { |h| h.notes&.start_with?('Day') }
      
      # Day 2 (most recent date) should come first
      expect(our_histories[0].notes).to eq('Day 2 - Single')
      
      # Day 1 entries should follow, ordered by id DESC within the same date
      # tracker2 was created after tracker1, so it should come first
      day1_histories = our_histories.select { |h| h.notes&.start_with?('Day 1') }
      expect(day1_histories.length).to eq(2)
      expect(day1_histories[0].notes).to eq('Day 1 - Afternoon')
      expect(day1_histories[1].notes).to eq('Day 1 - Morning')
      
      # Verify within same date, higher ID comes first
      expect(day1_histories[0].id).to be > day1_histories[1].id
    end
  end

  describe 'panel view consistency with history view (#939)' do
    it 'shows the same latest entry in the trackers view as in the ordered tracker_history' do
      master = create_master

      # Create entries with same calendar date but different timestamps
      # This is the scenario that caused #939 — the panel view and history view
      # disagreed on which entry was "latest"
      same_day_morning = 2.days.ago.beginning_of_day + 8.hours
      same_day_evening = 2.days.ago.beginning_of_day + 20.hours

      master.trackers.create!(
        protocol_id: @p1.id,
        sub_process_id: @sp1_1.id,
        event_date: same_day_morning,
        notes: 'Same day - Morning entry'
      )

      master.trackers.create!(
        protocol_id: @p1.id,
        sub_process_id: @sp1_2.id,
        event_date: same_day_evening,
        notes: 'Same day - Evening entry'
      )

      # The trackers view (panel view) should show one entry per protocol
      panel_entries = master.trackers.reload.select { |t| t.protocol_id == @p1.id }
      expect(panel_entries.length).to eq 1
      panel_entry = panel_entries.first

      # The tracker_history (history view) ordered by the canonical ordering
      history_entries = master.tracker_histories.reload
                              .select { |h| h.protocol_id == @p1.id && h.notes&.start_with?('Same day') }

      # The panel entry should match the first (latest) history entry
      latest_history = history_entries.first
      expect(panel_entry.sub_process_id).to eq latest_history.sub_process_id
      expect(panel_entry.notes).to eq latest_history.notes
    end

    it 'orders entries by event_date date-only then id DESC (not timestamp)' do
      master = create_master

      # Insert entries where timestamp ordering differs from date+id ordering
      # Use mid-day times to avoid timezone-related date boundary crossings
      # Entry A: same date, created first (lower id)
      # Entry B: same date, created second (higher id)
      yesterday_time1 = 1.day.ago.beginning_of_day + 10.hours
      yesterday_time2 = 1.day.ago.beginning_of_day + 14.hours

      master.trackers.create!(
        protocol_id: @p1.id,
        sub_process_id: @sp1_1.id,
        event_date: yesterday_time1,
        notes: 'Entry A - earlier timestamp, lower id'
      )

      master.trackers.create!(
        protocol_id: @p1.id,
        sub_process_id: @sp1_2.id,
        event_date: yesterday_time2,
        notes: 'Entry B - later timestamp, higher id'
      )

      # Both are on the same calendar date, so the one with higher id should win
      panel_entries = master.trackers.reload.select { |t| t.protocol_id == @p1.id }
      expect(panel_entries.length).to eq 1
      # Entry B has the higher tracker_history id, so it should be shown in the panel
      expect(panel_entries.first.notes).to eq 'Entry B - later timestamp, higher id'
      expect(panel_entries.first.sub_process_id).to eq @sp1_2.id
    end
  end

  # Regression specs for issue #1106: Master#trackers_length raised
  # PG::SyntaxError ("syntax error at or near 'Table'") when the trackers
  # association carried eager_load values (from TrackerHandler default_scope
  # and the has_many lambda), causing an Arel::Attribute object to leak into
  # the generated SQL.  The memoization guard also had a falsy-zero bug.
  describe 'Master#trackers_length' do
    it 'returns the correct count when the association is not preloaded' do
      master = create_master
      # Use two distinct protocols so the trackers view shows two rows
      # (the view returns one row per protocol per master)
      master.trackers.create!(
        protocol_id: @p1.id, sub_process_id: @sp1_1.id, event_date: DateTime.now
      )
      master.trackers.create!(
        protocol_id: @p2.id, sub_process_id: @sp2_1.id, event_date: DateTime.now
      )

      # Reload so the association is NOT cached
      fresh = Master.find(master.id)
      fresh.current_user = @user

      expect { fresh.trackers_length }.not_to raise_error
      expect(fresh.trackers_length).to eq 2
    end

    it 'returns 0 (not nil) and does not re-query when the master has no trackers' do
      master = create_master
      fresh = Master.find(master.id)
      fresh.current_user = @user

      expect(fresh.trackers_length).to eq 0

      # Second call must use the memoized value, not hit the DB again
      query_count = 0
      counter = ->(_name, _started, _finished, _unique_id, payload) {
        query_count += 1 if payload[:sql]&.match?(/tracker/i)
      }
      ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') do
        fresh.trackers_length
      end
      expect(query_count).to eq 0
    end

    it 'uses trackers.length (not a SQL count) when the association is already loaded' do
      master = create_master
      master.trackers.create!(
        protocol_id: @p1.id, sub_process_id: @sp1_1.id, event_date: DateTime.now
      )
      master.trackers.load # preload

      query_count = 0
      counter = ->(_name, _started, _finished, _unique_id, payload) {
        query_count += 1 if payload[:sql]&.match?(/tracker/i)
      }
      ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') do
        master.trackers_length
      end
      expect(query_count).to eq 0
      expect(master.trackers_length).to eq 1
    end
  end
end
