# frozen_string_literal: true

# Purpose: regression coverage for GitHub issue #1312. Saving a selector-backed
# classification must not clear unrelated Rails cache entries.

require 'rails_helper'

RSpec.describe Classification::GeneralSelection, type: :model do
  include ModelSupport

  before :example do
    create_admin
  end

  it 'preserves unrelated cache entries when a general selection is created (GitHub #1312)' do
    cache_key = 'issue-1312-unrelated-cache-entry'
    Rails.cache.write(cache_key, 'keep me')

    Classification::GeneralSelection.create!(item_type: 'player_contacts_type',
                                             name: 'Issue 1312 cache test',
                                             value: 'issue_1312_cache_test',
                                             current_admin: @admin)

    expect(Rails.cache.read(cache_key)).to eq('keep me')
  end

  it 'refreshes a cached selector collection when a general selection is created (GitHub #1312)' do
    item_type = 'issue_1312_create_selector_cache'
    Classification::GeneralSelection.selector_collection(item_type:)

    Classification::GeneralSelection.create!(item_type:, name: 'Created selection',
                                             value: 'created_selection', current_admin: @admin)

    names = Classification::GeneralSelection.selector_collection(item_type:).map { |selection| selection['name'] }
    expect(names).to include('Created selection')
  end

  it 'refreshes a cached selector collection when a general selection is updated (GitHub #1312)' do
    item_type = 'issue_1312_update_selector_cache'
    selection = Classification::GeneralSelection.create!(item_type:, name: 'Original selection',
                                                         value: 'original_selection', current_admin: @admin)
    Classification::GeneralSelection.selector_collection(item_type:)

    selection.current_admin = @admin
    selection.update!(name: 'Updated selection')

    names = Classification::GeneralSelection.selector_collection(item_type:).map { |item| item['name'] }
    expect(names).to include('Updated selection')
    expect(names).not_to include('Original selection')
  end
end
