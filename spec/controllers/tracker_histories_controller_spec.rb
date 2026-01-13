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
      it 'returns tracker histories ordered by id descending' do
        master = create_master
        
        # Create multiple tracker entries with different event dates
        # to ensure we're testing id ordering, not event_date ordering
        protocol = Classification::Protocol.create!(name: "Test Protocol #{rand(100_000)}", current_admin: @admin)
        sub_process = protocol.sub_processes.create!(name: "Test Sub Process #{rand(100_000)}", 
                                                      disabled: false, 
                                                      current_admin: @admin)
        
        # Create trackers with dates in non-sequential order to test id DESC sorting
        tracker1 = master.trackers.create!(
          protocol_id: protocol.id,
          sub_process_id: sub_process.id,
          event_date: 3.days.ago,
          notes: 'First tracker'
        )
        
        tracker2 = master.trackers.create!(
          protocol_id: protocol.id,
          sub_process_id: sub_process.id,
          event_date: 1.day.ago,
          notes: 'Second tracker'
        )
        
        tracker3 = master.trackers.create!(
          protocol_id: protocol.id,
          sub_process_id: sub_process.id,
          event_date: 2.days.ago,
          notes: 'Third tracker'
        )
        
        get :index, params: { master_id: master.id }
        
        expect(response).to have_http_status(200)
        
        json_response = JSON.parse(response.body)
        tracker_histories = json_response['tracker_histories']
        
        expect(tracker_histories).to be_an(Array)
        expect(tracker_histories.length).to be >= 3
        
        # Extract ids from the response
        ids = tracker_histories.map { |th| th['id'] }
        
        # Verify ids are in descending order
        expect(ids).to eq(ids.sort.reverse)
        
        # Verify the most recent (highest id) is first
        expect(ids.first).to be > ids.last
      end
    end

    context 'when requesting tracker histories for a specific tracker' do
      it 'returns tracker histories ordered by id descending' do
        master = create_master
        
        protocol = Classification::Protocol.create!(name: "Test Protocol #{rand(100_000)}", current_admin: @admin)
        sub_process = protocol.sub_processes.create!(name: "Test Sub Process #{rand(100_000)}", 
                                                      disabled: false, 
                                                      current_admin: @admin)
        
        # Create a tracker - this will have a tracker_history entry
        tracker = master.trackers.create!(
          protocol_id: protocol.id,
          sub_process_id: sub_process.id,
          event_date: DateTime.now,
          notes: 'Initial tracker'
        )
        
        # Update the tracker multiple times to create tracker_history entries
        tracker.update!(event_date: 1.day.from_now, notes: 'Updated once')
        tracker.update!(event_date: 2.days.from_now, notes: 'Updated twice')
        
        get :index, params: { master_id: master.id, tracker_id: tracker.id }
        
        expect(response).to have_http_status(200)
        
        json_response = JSON.parse(response.body)
        tracker_histories = json_response['tracker_histories']
        
        expect(tracker_histories).to be_an(Array)
        
        # Extract ids from the response
        ids = tracker_histories.map { |th| th['id'] }
        
        # Verify ids are in descending order
        expect(ids).to eq(ids.sort.reverse)
        
        # Most recent entry (highest id) should be first
        if ids.length > 1
          expect(ids.first).to be > ids.last
        end
      end

      it 'skips the most recent entry when skip_last=true' do
        master = create_master
        
        protocol = Classification::Protocol.create!(name: "Test Protocol #{rand(100_000)}", current_admin: @admin)
        sub_process = protocol.sub_processes.create!(name: "Test Sub Process #{rand(100_000)}", 
                                                      disabled: false, 
                                                      current_admin: @admin)
        
        # Create a tracker
        tracker = master.trackers.create!(
          protocol_id: protocol.id,
          sub_process_id: sub_process.id,
          event_date: DateTime.now,
          notes: 'Initial tracker'
        )
        
        # Update the tracker multiple times to create history
        tracker.update!(event_date: 1.day.from_now, notes: 'Updated once')
        tracker.update!(event_date: 2.days.from_now, notes: 'Updated twice')
        
        # Get all tracker histories first
        get :index, params: { master_id: master.id, tracker_id: tracker.id }
        all_histories = JSON.parse(response.body)['tracker_histories']
        most_recent_id = all_histories.first['id']
        
        # Now get with skip_last=true
        get :index, params: { master_id: master.id, tracker_id: tracker.id, skip_last: 'true' }
        
        expect(response).to have_http_status(200)
        
        json_response = JSON.parse(response.body)
        tracker_histories = json_response['tracker_histories']
        
        # Verify the most recent entry is not included
        returned_ids = tracker_histories.map { |th| th['id'] }
        expect(returned_ids).not_to include(most_recent_id)
        
        # Verify the remaining entries are still ordered by id descending
        expect(returned_ids).to eq(returned_ids.sort.reverse)
      end
    end
  end
end
