# frozen_string_literal: true

require 'rails_helper'

# Issue #1343 - the admin versions panel must limit the number of history rows
# fetched/displayed and expose the true total count, so admins aren't hit with
# a proxy timeout when a definition has a very large version history.
RSpec.describe Admin::ActivityLogsController, type: :controller do
  include AdminActivityLogSupport

  describe 'GET #versions with a large history' do
    before do
      create_admin
      sign_in @admin
      @activity_log = create_item(
        {
          name: 'test_al_version_limit',
          item_type: 'player_contact',
          rec_type: 'email',
          action_when_attribute: 'emailed_when',
          current_admin: @admin
        },
        @admin
      )
    end

    def insert_history_rows(count)
      count.times do |i|
        Admin::MigrationGenerator.connection.execute <<~SQL
          insert into activity_log_history (activity_log_id, name, item_type, rec_type, created_at, updated_at)
          values (
            #{@activity_log.id},
            'test_al_version_limit',
            'player_contact',
            'email',
            now() - interval '#{count - i} minutes',
            now() - interval '#{count - i} minutes'
          )
        SQL
      end
    end

    it 'limits the versions displayed and exposes the total count' do
      stub_const('Dynamic::VersionHandler::MAX_DISPLAYED_VERSIONS', 3)
      insert_history_rows(5)

      get :versions, params: { id: @activity_log.id }

      expect(response).to have_http_status(:ok)
      expect(assigns(:version_limit)).to eq(3)
      expect(assigns(:all_versions).length).to eq(3)
      expect(assigns(:total_version_count)).to be >= 5
    end

    it 'fetches a larger cumulative limit when a page param is given, and points "load more" at the next page' do
      stub_const('Dynamic::VersionHandler::MAX_DISPLAYED_VERSIONS', 3)
      insert_history_rows(10)

      get :versions, params: { id: @activity_log.id, page: 2 }

      expect(assigns(:version_limit)).to eq(6)
      expect(assigns(:all_versions).length).to eq(6)
      expect(assigns(:next_versions_page_path)).to include('page=3')
    end
  end
end
