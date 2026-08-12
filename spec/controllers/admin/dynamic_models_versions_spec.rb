# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::DynamicModelsController, type: :controller do
  include ModelSupport

  describe 'calculate_version_diffs' do
    before do
      create_admin
      @controller.instance_variable_set(:@current_admin, @admin)
    end

    it 'calculates diffs between consecutive versions' do
      versions = [
        {
          'id' => '1',
          'name' => 'test_model',
          'options' => "field_1: value_a\nfield_2: value_b",
          'created_at' => '2024-01-01 10:00:00',
          'updated_at' => '2024-01-02 10:00:00'
        },
        {
          'id' => '1',
          'name' => 'test_model',
          'options' => "field_1: value_a\nfield_2: value_old",
          'created_at' => '2024-01-01 10:00:00',
          'updated_at' => '2024-01-01 12:00:00'
        }
      ]

      diffs = @controller.send(:calculate_version_diffs, versions)

      expect(diffs.length).to eq(1)
      expect(diffs[0][:changes]['options']).to be_present
      expect(diffs[0][:changes]['options'][0]).to include('value_old')
      expect(diffs[0][:changes]['options'][1]).to include('value_b')
    end

    it 'returns empty array when there are no changes' do
      versions = [
        {
          'id' => '1',
          'name' => 'test_model',
          'options' => 'same content',
          'created_at' => '2024-01-01 10:00:00',
          'updated_at' => '2024-01-02 10:00:00'
        },
        {
          'id' => '1',
          'name' => 'test_model',
          'options' => 'same content',
          'created_at' => '2024-01-01 10:00:00',
          'updated_at' => '2024-01-01 12:00:00'
        }
      ]

      diffs = @controller.send(:calculate_version_diffs, versions)

      expect(diffs).to be_empty
    end

    it 'handles empty versions array' do
      diffs = @controller.send(:calculate_version_diffs, [])
      expect(diffs).to eq([])
    end

    it 'ignores id and def_version fields in diffs' do
      versions = [
        {
          'id' => '1',
          'def_version' => '100',
          'name' => 'test_model',
          'options' => 'content_new'
        },
        {
          'id' => '2',
          'def_version' => '99',
          'name' => 'test_model',
          'options' => 'content_old'
        }
      ]

      diffs = @controller.send(:calculate_version_diffs, versions)

      expect(diffs[0][:changes].keys).not_to include('id')
      expect(diffs[0][:changes].keys).not_to include('def_version')
      expect(diffs[0][:changes].keys).to include('options')
    end

    it 'normalizes line endings when comparing' do
      versions = [
        {
          'id' => '1',
          'options' => "line1\nline2\nline3"
        },
        {
          'id' => '1',
          'options' => "line1\r\nline2\r\nline3"
        }
      ]

      diffs = @controller.send(:calculate_version_diffs, versions)

      expect(diffs).to be_empty
    end
  end

  # Issue #1343 - the admin versions panel must limit the number of history rows
  # fetched/displayed and expose the true total count, so admins aren't hit with
  # a proxy timeout when a definition has a very large version history.
  describe 'GET #versions with a large history (issue #1343)' do
    include DynamicModelSupport

    before do
      @user0, = create_user
      create_admin
      create_user
      @dm = generate_test_dynamic_model
      sign_in @admin
    end

    def insert_history_rows(count)
      count.times do |i|
        Admin::MigrationGenerator.connection.execute <<~SQL
          insert into dynamic_model_history (dynamic_model_id, name, table_name, created_at, updated_at)
          values (
            #{@dm.id},
            '#{@dm.name}',
            '#{@dm.table_name}',
            now() - interval '#{count - i} minutes',
            now() - interval '#{count - i} minutes'
          )
        SQL
      end
    end

    it 'limits the versions displayed and exposes the total count' do
      stub_const('Dynamic::VersionHandler::MAX_DISPLAYED_VERSIONS', 3)
      insert_history_rows(5)

      get :versions, params: { id: @dm.id }

      expect(response).to have_http_status(:ok)
      expect(assigns(:version_limit)).to eq(3)
      expect(assigns(:all_versions).length).to eq(3)
      expect(assigns(:total_version_count)).to be >= 5
    end

    it 'fetches a larger cumulative limit when a page param is given, and points "load more" at the next page' do
      stub_const('Dynamic::VersionHandler::MAX_DISPLAYED_VERSIONS', 3)
      insert_history_rows(10)

      get :versions, params: { id: @dm.id, page: 2 }

      expect(assigns(:version_limit)).to eq(6)
      expect(assigns(:all_versions).length).to eq(6)
      expect(assigns(:next_versions_page_path)).to include('page=3')
    end
  end
end
