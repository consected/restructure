require 'rails_helper'

RSpec.describe TrackerHistoriesController, type: :controller do
  include UserSupport
  include TrackerSupport
  include ModelSupport

  before :each do
    admin, = ControllerMacros.create_admin
    @admin = admin
    validate_scantron_setup
    before_each_login_user
  end

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
        if day1_histories.length == 2
          expect(day1_histories[0]['id']).to be > day1_histories[1]['id']
        end
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
        tracker.update!(event_date: 2.days.ago.beginning_of_day + 11.hours, notes: 'Updated to 2 days ago')
        tracker.update!(event_date: 1.day.ago.beginning_of_day + 12.hours, notes: 'Updated to 1 day ago')
        
        get :index, params: { master_id: master.id, tracker_id: tracker.id }
        
        expect(response).to have_http_status(200)
        
        json_response = JSON.parse(response.body)
        tracker_histories = json_response['tracker_histories']
        
        expect(tracker_histories).to be_an(Array)
        
        # Verify ordering: most recent event_date first
        if tracker_histories.length >= 3
          dates = tracker_histories.map { |th| th['event_date'] ? Date.parse(th['event_date']) : nil }.compact
          expect(dates).to eq(dates.sort.reverse)
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
  end
end
