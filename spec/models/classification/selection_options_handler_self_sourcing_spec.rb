# frozen_string_literal: true

# Purpose: Lock in the behaviour of Classification::SelectionOptionsHandler.self_sourcing_field?
# (GitHub Issue #1228, Group C regression).
#
# "Self-sourcing" fields derive their own selection options at runtime from the field-name
# suffix - records from a master association (select_record_from_*, select_record_id_from_*,
# pick_multiple_records_from_table_*, with optional tag_ prefix) or users holding a role
# (select_user_with_role_*, tag_select_users_with_role_*). They are rendered by dedicated
# `_name_starts_with_*` edit_fields partials and never require a persisted general selection
# or an edit_as override, so the dynamic model config validator must never flag them as
# "missing general selection config".
#
# These tests verify:
#   - Each self-sourcing prefix family is recognised (true)
#   - The three field names that triggered the original Group C failures are recognised
#   - General-selection-backed selection fields (select_status, source, rank, multi_*, etc.)
#     are NOT treated as self-sourcing (false), so they remain subject to validation
#   - A bare prefix with no suffix is not matched (a suffix is required to derive a source)

require 'rails_helper'

RSpec.describe Classification::SelectionOptionsHandler, type: :model do
  describe '.self_sourcing_field?' do
    self_sourcing_examples = %w[
      select_record_from_addresses
      select_record_from_table_player_contacts
      select_record_id_from_addresses
      select_record_id_from_table_player_contacts
      pick_multiple_records_from_table_player_contacts
      tag_select_record_from_addresses
      tag_select_record_id_from_addresses
      select_user_with_role_perform_phone_screen
      tag_select_users_with_role_admin
    ]

    self_sourcing_examples.each do |field_name|
      it "returns true for self-sourcing field #{field_name}" do
        expect(described_class.self_sourcing_field?(field_name)).to be true
      end
    end

    # Fields that source their options from general selections (or fixed config) and so
    # must remain subject to the missing-general-selection validation.
    general_selection_backed_examples = %w[
      select_status
      select_who
      source
      rec_type
      rank
      multi_choices
      tag_select_some_values
      some_selection
    ]

    general_selection_backed_examples.each do |field_name|
      it "returns false for general-selection-backed field #{field_name}" do
        expect(described_class.self_sourcing_field?(field_name)).to be false
      end
    end

    it 'requires a suffix after the prefix' do
      # A bare prefix cannot derive a data source, so it is not self-sourcing
      expect(described_class.self_sourcing_field?('select_record_from')).to be false
    end

    it 'accepts symbols as well as strings' do
      expect(described_class.self_sourcing_field?(:select_user_with_role_perform_phone_screen)).to be true
    end
  end
end
