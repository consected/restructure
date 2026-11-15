# frozen_string_literal: true

# Classification::GeneralSelection Model Spec
#
# Tests core general selection functionality including caching, deduplication, and
# attribute classification.
#
# Regression Coverage:
# - use_with_attribute? (GitHub #1228):
#   This is a pure naming-convention predicate identifying selection-like attributes.
#   It is intentionally shared (also used by Dynamic::DefHandler.item_types to build the
#   admin general-selection dropdown registry), so it must NOT special-case self-sourcing
#   fields. The self-sourcing exemption (select_record_from_*, select_user_with_role_*, etc.)
#   lives in Classification::SelectionOptionsHandler.self_sourcing_field? and is exercised by
#   spec/models/classification/selection_options_handler_self_sourcing_spec.rb.

require 'rails_helper'

RSpec.describe Classification::GeneralSelection, type: :model do
  include ModelSupport
  include GeneralSelectionSupport

  before :example do
    create_admin
    create_user

    create_master
    create_items :list_valid_attribs
  end

  describe '.use_with_attribute?' do
    # Selection-like attributes by naming convention
    %w[select_status select_who select_type multi_items tag_select_labels
       source rec_type rank outcome_selection].each do |attr|
      it "returns true for #{attr}" do
        expect(described_class.use_with_attribute?(attr)).to be true
      end
    end

    # Self-sourcing fields are still selection-like by name, so use_with_attribute?
    # returns true. They are exempted from missing-general-selection validation
    # separately, via SelectionOptionsHandler.self_sourcing_field?.
    %w[select_record_from_player_contact_email
       select_record_from_addresses
       select_user_with_role_perform_phone_screen].each do |attr|
      it "returns true for the self-sourcing field #{attr}" do
        expect(described_class.use_with_attribute?(attr)).to be true
      end
    end

    # System fields that are never configurable
    %w[disabled user_id created_at updated_at].each do |attr|
      it "returns false for the system field #{attr}" do
        expect(described_class.use_with_attribute?(attr)).to be false
      end
    end
  end

  it 'gets active general selection configurations' do
    expect(@list.length).to eq 10

    l = Classification::GeneralSelection.active.length
    expect(l).to be > 10

    res = Classification::GeneralSelection.selector_with_config_overrides
    expect(res.length).to be >= l
  end

  it 'prevents duplicate entries with the same value in an item type' do
    g = Classification::GeneralSelection.new item_type: 'player_contacts_type', name: 'Not Email', value: 'not email', current_admin: @admin
    expect(g.already_taken(:item_type, :value)).to be false

    expect(g.save).to be true

    g = Classification::GeneralSelection.new item_type: 'player_contacts_type', name: 'Email', value: 'email', current_admin: @admin
    expect(g.already_taken(:item_type, :value)).to be true

    expect(g.save).to be false
    expect(g.errors.attribute_names).to include :duplicated
  end
end
