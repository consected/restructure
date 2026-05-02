# frozen_string_literal: true

# Specs for TrackerHistoriesController - verifies the JSON payload returned
# by the index action, including the `initial_filter_*` keys added for the
# tracker history panel filter feature (consected/restructure issue #1074).

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
      it 'returns tracker histories ordered by event_date::date DESC, then id DESC' do
        master = create_master

        protocol = Classification::Protocol.create!(name: "Test Protocol #{rand(100_000)}", current_admin: @admin)
        sub_process = protocol.sub_processes.create!(name: "Test Sub Process #{rand(100_000)}",
                                                     disabled: false,
                                                     current_admin: @admin)

        # Create trackers with specific dates to test the ordering
        # Day 1: Two trackers on the same date (different times) - should be ordered by id DESC
        day1_time1 = 3.days.ago.beginning_of_day + 9.hours
        day1_time2 = 3.days.ago.beginning_of_day + 14.hours

        tracker1 = master.trackers.create!(
          protocol_id: protocol.id,
          sub_process_id: sub_process.id,
          event_date: day1_time1,
          notes: 'Day 1 - Morning'
        )

        tracker2 = master.trackers.create!(
          protocol_id: protocol.id,
          sub_process_id: sub_process.id,
          event_date: day1_time2,
          notes: 'Day 1 - Afternoon'
        )

        # Day 2: One tracker
        tracker3 = master.trackers.create!(
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

        # Day 1 entries should come after, ordered by id DESC (later created first)
        # tracker2 was created after tracker1, so it should come first
        expect(our_histories[1]['notes']).to eq('Day 1 - Afternoon')
        expect(our_histories[2]['notes']).to eq('Day 1 - Morning')

        # Verify IDs: within same date, higher ID comes first
        day1_histories = our_histories.select { |th| th['notes']&.start_with?('Day 1') }
        expect(day1_histories[0]['id']).to be > day1_histories[1]['id'] if day1_histories.length == 2
      end
    end

    context 'when requesting tracker histories for a specific tracker' do
      it 'returns tracker histories ordered by event_date::date DESC, then id DESC' do
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
        # Create another update on the same date to test id DESC ordering within same date
        tracker.update!(event_date: 2.days.ago.beginning_of_day + 15.hours, notes: 'Updated to 2 days ago - second')
        tracker.update!(event_date: 1.day.ago.beginning_of_day + 12.hours, notes: 'Updated to 1 day ago')

        get :index, params: { master_id: master.id, tracker_id: tracker.id }

        expect(response).to have_http_status(200)

        json_response = JSON.parse(response.body)
        tracker_histories = json_response['tracker_histories']

        expect(tracker_histories).to be_an(Array)
        expect(tracker_histories.length).to be >= 4

        # Verify ordering: most recent event_date::date first
        dates = tracker_histories.map { |th| th['event_date'] ? Date.parse(th['event_date']) : nil }.compact
        expect(dates).to eq(dates.sort.reverse)

        # Verify id DESC within same date: find entries from 2 days ago
        same_date_entries = tracker_histories.select do |th|
          th['notes']&.include?('2 days ago')
        end

        # Within same date, higher ID (later created) should come first
        if same_date_entries.length == 2
          expect(same_date_entries[0]['notes']).to eq('Updated to 2 days ago - second')
          expect(same_date_entries[1]['notes']).to eq('Updated to 2 days ago - first')
          expect(same_date_entries[0]['id']).to be > same_date_entries[1]['id']
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
    end

    # Issue #1074: tracker history panel filtering
    context 'when the tracker history initial filters app config is set' do
      it 'includes initial_filter_regex in the JSON response' do
        master = create_master

        Admin::AppConfiguration.add_default_config(
          @user.app_type,
          :tracker_history_initial_filters,
          "protocols: '^Study'\nsub_processes: 'consented'\n",
          @admin
        )

        get :index, params: { master_id: master.id }

        expect(response).to have_http_status(200)
        json_response = JSON.parse(response.body)
        expect(json_response['initial_filter_regex']).to eq(
          'protocols' => '^Study',
          'sub_processes' => 'consented'
        )
      end

      it 'includes the literal initial_filter_notes value in the JSON response' do
        master = create_master

        Admin::AppConfiguration.add_default_config(
          @user.app_type,
          :tracker_history_initial_filters,
          "notes: 'follow-up'\n",
          @admin
        )

        get :index, params: { master_id: master.id }

        expect(response).to have_http_status(200)
        json_response = JSON.parse(response.body)
        expect(json_response['initial_filter_notes']).to eq('follow-up')
      end

      it 'returns an empty initial_filter_regex and notes when no config is set' do
        master = create_master
        get :index, params: { master_id: master.id }
        expect(response).to have_http_status(200)
        json_response = JSON.parse(response.body)
        expect(json_response['initial_filter_regex']).to eq({})
        expect(json_response['initial_filter_notes']).to eq('')
      end

      it 'includes the record_updates_protocol_name from Classification::Protocol' do
        master = create_master
        get :index, params: { master_id: master.id }
        expect(response).to have_http_status(200)
        json_response = JSON.parse(response.body)
        expect(json_response['record_updates_protocol_name'])
          .to eq(Classification::Protocol::RecordUpdatesProtocolName)
      end
    end
  end
end
