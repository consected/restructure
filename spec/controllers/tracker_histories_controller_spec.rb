# frozen_string_literal: true

# Tests for TrackerHistoriesController, verifying correct ordering of tracker history entries.
# Tracker histories are ordered by full event_date timestamp DESC, then id DESC.
# This ensures consistency between the tracker panel (tree view) and the full
# chronological tracker history, matching the DB upsert trigger's determination
# of which entry is "latest" for a protocol. See issue #939.
require 'rails_helper'

RSpec.describe TrackerHistoriesController, type: :controller do
  include UserSupport
  include TrackerSupport
  include ModelSupport

  before :each do
    admin, = ControllerMacros.create_admin
    @admin = admin
    validate_scantron_setup
  end

  before_each_login_user

  describe 'GET #index' do
    context 'when requesting tracker histories for a master' do
      it 'returns tracker histories ordered by full event_date timestamp DESC, then id DESC' do
        master = create_master

        protocol = Classification::Protocol.create!(name: "Test Protocol #{rand(100_000)}", current_admin: @admin)
        sub_process = protocol.sub_processes.create!(name: "Test Sub Process #{rand(100_000)}",
                                                     disabled: false,
                                                     current_admin: @admin)

        # Create trackers with specific dates to test the ordering
        # Day 1: Two trackers on the same date (different times) - should be ordered by timestamp DESC
        day1_time1 = 3.days.ago.beginning_of_day + 9.hours
        day1_time2 = 3.days.ago.beginning_of_day + 14.hours

        master.trackers.create!(
          protocol_id: protocol.id,
          sub_process_id: sub_process.id,
          event_date: day1_time1,
          notes: 'Day 1 - Morning'
        )

        master.trackers.create!(
          protocol_id: protocol.id,
          sub_process_id: sub_process.id,
          event_date: day1_time2,
          notes: 'Day 1 - Afternoon'
        )

        # Day 2: One tracker
        master.trackers.create!(
          protocol_id: protocol.id,
          sub_process_id: sub_process.id,
          event_date: 1.day.ago.beginning_of_day + 10.hours,
          notes: 'Day 2 - Single'
        )

        get :index, params: { master_id: master.id }

        expect(response).to have_http_status(200)

        json_response = JSON.parse(response.body)
        tracker_histories = json_response['tracker_histories']

        expect(tracker_histories).to be_an(Array)
        expect(tracker_histories.length).to be >= 3

        # Get the tracker histories we created (filter by notes to identify them)
        our_histories = tracker_histories.select { |th| th['notes']&.start_with?('Day') }

        # Day 2 (most recent date) should come first
        expect(our_histories[0]['notes']).to eq('Day 2 - Single')

        # Day 1 entries should come after, ordered by timestamp DESC
        # Afternoon (14:00) has a later timestamp than Morning (09:00), so it comes first
        expect(our_histories[1]['notes']).to eq('Day 1 - Afternoon')
        expect(our_histories[2]['notes']).to eq('Day 1 - Morning')
      end
    end

    context 'when requesting tracker histories for a specific tracker' do
      it 'returns tracker histories ordered by full event_date timestamp DESC, then id DESC' do
        master = create_master

        protocol = Classification::Protocol.create!(name: "Test Protocol #{rand(100_000)}", current_admin: @admin)
        sub_process = protocol.sub_processes.create!(name: "Test Sub Process #{rand(100_000)}",
                                                     disabled: false,
                                                     current_admin: @admin)

        # Create a tracker with a specific date
        tracker = master.trackers.create!(
          protocol_id: protocol.id,
          sub_process_id: sub_process.id,
          event_date: 3.days.ago.beginning_of_day + 10.hours,
          notes: 'Initial tracker'
        )

        # Update with different dates to create history entries
        tracker.update!(event_date: 2.days.ago.beginning_of_day + 11.hours, notes: 'Updated to 2 days ago - first')
        # Create another update on the same date to test ordering within same date
        tracker.update!(event_date: 2.days.ago.beginning_of_day + 15.hours, notes: 'Updated to 2 days ago - second')
        tracker.update!(event_date: 1.day.ago.beginning_of_day + 12.hours, notes: 'Updated to 1 day ago')

        get :index, params: { master_id: master.id, tracker_id: tracker.id }

        expect(response).to have_http_status(200)

        json_response = JSON.parse(response.body)
        tracker_histories = json_response['tracker_histories']

        expect(tracker_histories).to be_an(Array)
        expect(tracker_histories.length).to be >= 4

        # Verify ordering: full timestamps should be in descending order
        dates = tracker_histories.map { |th| th['event_date'] ? DateTime.parse(th['event_date']) : nil }.compact
        expect(dates).to eq(dates.sort.reverse)

        # Verify within same date: entry with later timestamp should come first
        same_date_entries = tracker_histories.select do |th|
          th['notes']&.include?('2 days ago')
        end

        # Within same date, the one with the later timestamp (15:00) should come before (11:00)
        if same_date_entries.length == 2
          expect(same_date_entries[0]['notes']).to eq('Updated to 2 days ago - second')
          expect(same_date_entries[1]['notes']).to eq('Updated to 2 days ago - first')
        end
      end

      it 'skips the first entry (by order) when skip_last=true' do
        master = create_master

        protocol = Classification::Protocol.create!(name: "Test Protocol #{rand(100_000)}", current_admin: @admin)
        sub_process = protocol.sub_processes.create!(name: "Test Sub Process #{rand(100_000)}",
                                                     disabled: false,
                                                     current_admin: @admin)

        # Create a tracker
        tracker = master.trackers.create!(
          protocol_id: protocol.id,
          sub_process_id: sub_process.id,
          event_date: 3.days.ago.beginning_of_day,
          notes: 'Initial tracker'
        )

        # Update the tracker multiple times to create history
        tracker.update!(event_date: 2.days.ago.beginning_of_day, notes: 'Updated once')
        tracker.update!(event_date: 1.day.ago.beginning_of_day, notes: 'Updated twice')

        # Get all tracker histories first
        get :index, params: { master_id: master.id, tracker_id: tracker.id }
        all_histories = JSON.parse(response.body)['tracker_histories']
        first_entry_id = all_histories.first['id']

        # Now get with skip_last=true (which skips the first entry after ordering)
        get :index, params: { master_id: master.id, tracker_id: tracker.id, skip_last: 'true' }

        expect(response).to have_http_status(200)

        json_response = JSON.parse(response.body)
        tracker_histories = json_response['tracker_histories']

        # Verify the first entry from the ordered list is not included
        returned_ids = tracker_histories.map { |th| th['id'] }
        expect(returned_ids).not_to include(first_entry_id)
      end

      it 'orders tracker history consistently with the tracker panel view (issue #939)' do
        # Reproduces issue #939: when events share the same date but have
        # different timestamps, the history ordering should match the
        # upsert trigger's "latest" determination (full timestamp comparison).
        master = create_master

        protocol = Classification::Protocol.create!(name: "Test Protocol #{rand(100_000)}", current_admin: @admin)
        sub_process1 = protocol.sub_processes.create!(name: "Sent #{rand(100_000)}",
                                                      disabled: false,
                                                      current_admin: @admin)
        sub_process2 = protocol.sub_processes.create!(name: "Complete #{rand(100_000)}",
                                                      disabled: false,
                                                      current_admin: @admin)

        event_day = 2.days.ago.beginning_of_day

        # Create entries with timestamps that don't match their insertion order
        # Entry 1: event_date 08:00 (earliest timestamp, lowest ID)
        master.trackers.create!(
          protocol_id: protocol.id,
          sub_process_id: sub_process1.id,
          event_date: event_day + 8.hours,
          notes: 'Sent, Invitation Email'
        )

        # Entry 2: event_date 09:00 (middle timestamp, middle ID)
        master.trackers.create!(
          protocol_id: protocol.id,
          sub_process_id: sub_process1.id,
          event_date: event_day + 9.hours,
          notes: 'Sent, Marketo Email'
        )

        # Entry 3: event_date 15:00 (latest timestamp, highest ID)
        master.trackers.create!(
          protocol_id: protocol.id,
          sub_process_id: sub_process2.id,
          event_date: event_day + 15.hours,
          notes: 'Complete, Redcap'
        )

        # The tracker panel (upsert trigger) should show 'Complete, Redcap'
        # as the current entry for this protocol (latest by timestamp)
        current_tracker = master.trackers.where(protocol_id: protocol.id).first
        expect(current_tracker.notes).to eq('Complete, Redcap')

        # The full history should be ordered by timestamp DESC,
        # matching the tracker panel's view
        get :index, params: { master_id: master.id, tracker_id: current_tracker.id }

        json_response = JSON.parse(response.body)
        tracker_histories = json_response['tracker_histories']

        our_histories = tracker_histories.select { |th| th['notes']&.match?(/Sent|Complete/) }

        # Verify order matches the tracker panel: latest timestamp first
        expect(our_histories[0]['notes']).to eq('Complete, Redcap')
        expect(our_histories[1]['notes']).to eq('Sent, Marketo Email')
        expect(our_histories[2]['notes']).to eq('Sent, Invitation Email')
      end
    end
  end
end
