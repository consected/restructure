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
end
