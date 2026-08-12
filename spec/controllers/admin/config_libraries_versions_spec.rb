# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ConfigLibrariesController, type: :controller do
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
          'name' => 'test_library',
          'category' => 'test_category',
          'options' => "key_1: value_a\nkey_2: value_b",
          'created_at' => '2024-01-01 10:00:00',
          'updated_at' => '2024-01-02 10:00:00'
        },
        {
          'id' => '1',
          'name' => 'test_library',
          'category' => 'test_category',
          'options' => "key_1: value_a\nkey_2: value_old",
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

    it 'excludes created_at/updated_at from the diffed changes even when timestamps differ alongside a real change' do
      # created_at/updated_at are already shown in the header row for each
      # version - they should not also appear as a diffed field.
      versions = [
        {
          'id' => '1',
          'name' => 'test_library',
          'category' => 'test_category',
          'options' => 'content_new',
          'created_at' => '2024-01-01 10:00:00',
          'updated_at' => '2024-01-02 10:00:00'
        },
        {
          'id' => '1',
          'name' => 'test_library',
          'category' => 'test_category',
          'options' => 'content_old',
          'created_at' => '2024-01-01 10:00:00',
          'updated_at' => '2024-01-01 12:00:00'
        }
      ]

      diffs = @controller.send(:calculate_version_diffs, versions)

      expect(diffs[0][:changes].keys).not_to include('created_at')
      expect(diffs[0][:changes].keys).not_to include('updated_at')
      expect(diffs[0][:changes].keys).to include('options')
    end

    it 'returns empty array when there are no changes' do
      versions = [
        {
          'id' => '1',
          'name' => 'test_library',
          'category' => 'test_category',
          'options' => 'same content',
          'created_at' => '2024-01-01 10:00:00',
          'updated_at' => '2024-01-02 10:00:00'
        },
        {
          'id' => '1',
          'name' => 'test_library',
          'category' => 'test_category',
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
          'name' => 'test_library',
          'category' => 'test_category',
          'options' => 'content_new'
        },
        {
          'id' => '2',
          'def_version' => '99',
          'name' => 'test_library',
          'category' => 'test_category',
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
          'name' => 'test_library',
          'category' => 'test_category',
          'options' => "line1\nline2\nline3"
        },
        {
          'id' => '1',
          'name' => 'test_library',
          'category' => 'test_category',
          'options' => "line1\r\nline2\r\nline3"
        }
      ]

      diffs = @controller.send(:calculate_version_diffs, versions)

      expect(diffs).to be_empty
    end

    it 'filters out timestamp-only changes' do
      versions = [
        {
          'id' => '1',
          'name' => 'test_library',
          'category' => 'test_category',
          'options' => 'same content',
          'created_at' => '2024-01-01 10:00:00',
          'updated_at' => '2024-01-02 10:00:00'
        },
        {
          'id' => '1',
          'name' => 'test_library',
          'category' => 'test_category',
          'options' => 'same content',
          'created_at' => '2024-01-01 10:00:00',
          'updated_at' => '2024-01-01 12:00:00'
        }
      ]

      diffs = @controller.send(:calculate_version_diffs, versions)

      # Should be empty because only timestamps changed
      expect(diffs).to be_empty
    end
  end

  # Issue #1343 - the admin versions panel must limit the number of history rows
  # fetched/displayed and expose the true total count, so admins aren't hit with
  # a proxy timeout when a definition has a very large version history.
  describe 'GET #versions with a large history (issue #1343)' do
    before do
      create_admin
      sign_in @admin
      @library = Admin::ConfigLibrary.create!(
        current_admin: @admin,
        name: 'test_version_limit_library',
        category: 'test',
        format: 'yaml',
        options: "field_1:\n  label: First Field"
      )
    end

    def insert_history_rows(count)
      count.times do |i|
        Admin::MigrationGenerator.connection.execute <<~SQL
          insert into config_library_history (config_library_id, name, category, format, created_at, updated_at)
          values (
            #{@library.id},
            'test_version_limit_library',
            'test',
            'yaml',
            now() - interval '#{count - i} minutes',
            now() - interval '#{count - i} minutes'
          )
        SQL
      end
    end

    it 'limits the versions displayed and exposes the total count' do
      stub_const('Dynamic::VersionHandler::MAX_DISPLAYED_VERSIONS', 3)
      insert_history_rows(5)

      get :versions, params: { id: @library.id }

      expect(response).to have_http_status(:ok)
      expect(assigns(:version_limit)).to eq(3)
      expect(assigns(:all_versions).length).to eq(3)
      expect(assigns(:total_version_count)).to be >= 5
    end

    it 'does not limit or report an inflated count when history is below the limit' do
      get :versions, params: { id: @library.id }

      expect(assigns(:total_version_count)).to eq(1)
      expect(assigns(:all_versions).length).to eq(1)
    end

    it 'fetches a larger cumulative limit when a page param is given' do
      stub_const('Dynamic::VersionHandler::MAX_DISPLAYED_VERSIONS', 3)
      insert_history_rows(10)

      get :versions, params: { id: @library.id, page: 2 }

      expect(assigns(:version_limit)).to eq(6)
      expect(assigns(:all_versions).length).to eq(6)
    end

    it 'treats a blank or invalid page param as page 1' do
      stub_const('Dynamic::VersionHandler::MAX_DISPLAYED_VERSIONS', 3)
      insert_history_rows(5)

      get :versions, params: { id: @library.id, page: '0' }

      expect(assigns(:version_limit)).to eq(3)
    end

    context 'rendered view' do
      render_views

      it 'does not show a truncation note when the count is exactly at the limit' do
        stub_const('Dynamic::VersionHandler::MAX_DISPLAYED_VERSIONS', 3)
        insert_history_rows(2) # 1 (from create!) + 2 = 3, exactly at the limit

        get :versions, params: { id: @library.id }

        expect(assigns(:total_version_count)).to eq(3)
        expect(assigns(:all_versions).length).to eq(3)
        expect(response.body).to include('3 versions')
        expect(response.body).not_to include('most recent')
      end

      it 'shows a truncation note as soon as the count exceeds the limit' do
        stub_const('Dynamic::VersionHandler::MAX_DISPLAYED_VERSIONS', 3)
        insert_history_rows(3) # 1 (from create!) + 3 = 4, one over the limit

        get :versions, params: { id: @library.id }

        expect(assigns(:total_version_count)).to eq(4)
        expect(response.body).to include('4 versions')
        expect(response.body).to include('most recent 3 versions shown')
      end

      it 'shows a "load more" link to the next page when more versions remain' do
        stub_const('Dynamic::VersionHandler::MAX_DISPLAYED_VERSIONS', 3)
        insert_history_rows(3) # 1 (from create!) + 3 = 4, one over the limit

        get :versions, params: { id: @library.id }

        expect(response.body).to include('Load')
        expect(response.body).to include('page=2')
      end

      it 'does not show a "load more" link once all versions are loaded' do
        stub_const('Dynamic::VersionHandler::MAX_DISPLAYED_VERSIONS', 3)
        insert_history_rows(2) # 1 (from create!) + 2 = 3, exactly at the limit

        get :versions, params: { id: @library.id }

        expect(response.body).not_to include('page=2')
      end

      it 'fetches the next cumulative page when the "load more" link is followed' do
        stub_const('Dynamic::VersionHandler::MAX_DISPLAYED_VERSIONS', 3)
        insert_history_rows(10) # 1 (from create!) + 10 = 11

        get :versions, params: { id: @library.id, page: 2 }

        expect(assigns(:version_limit)).to eq(6)
        expect(assigns(:all_versions).length).to eq(6)
        expect(response.body).to include('page=3') # still more remaining (11 total)
      end
    end
  end
end
