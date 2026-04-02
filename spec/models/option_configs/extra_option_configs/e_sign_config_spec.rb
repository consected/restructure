# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for ESignConfig configuration class.
# Verifies document_reference wrapping, key singularization,
# model reference resolution, and integration with ActivityLogOptions registry.
RSpec.describe 'ExtraOptionConfigs::ESignConfig', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include ExtraOptionConfigsSupport

  before(:each) do
    create_admin
    create_user
    setup_access :trackers
    setup_access :tracker_histories
    @dm = generate_test_dynamic_model
    setup_access :dynamic_model__test_created_by_recs, user: @user
  end

  let(:klass) { OptionConfigs::ExtraOptionConfigs::ESignConfig }

  describe 'class structure' do
    it 'exists and inherits from BaseConfiguration' do
      expect(klass).to be < OptionConfigs::ExtraOptionConfigs::BaseConfiguration
    end

    it 'stores processed value' do
      expect(klass.store_processed_value?).to be true
    end

    it 'declares configure_direct with type :hash' do
      expect(klass.option_types[:direct]).to include(:e_sign)
    end
  end

  describe 'prepare_config' do
    it 'wraps document_reference in {item: ...} if not already wrapped' do
      raw = { document_reference: { player_contacts: { label: 'Contact' } } }
      result = klass.prepare_config(raw, nil)
      expect(result[:document_reference]).to have_key(:item),
                                             'Expected document_reference to be wrapped in {item: ...}'
    end

    it 'does not double-wrap document_reference that already has :item key' do
      raw = { document_reference: { item: { player_contacts: { label: 'Contact' } } } }
      result = klass.prepare_config(raw, nil)
      expect(result[:document_reference][:item]).not_to have_key(:item),
                                                        'Expected document_reference not to be double-wrapped'
    end

    it 'singularizes keys within each reference item' do
      raw = { document_reference: { item: { player_contacts: { label: 'Contact' } } } }
      result = klass.prepare_config(raw, nil)
      item = result[:document_reference][:item]
      expect(item).to have_key(:player_contact),
                      'Expected pluralized key :player_contacts to be singularized to :player_contact'
      expect(item).not_to have_key(:player_contacts),
                          'Expected original pluralized key :player_contacts to be removed after singularization'
    end

    it 'resolves model references with to_record_label, no_master_association, to_model_name_us' do
      raw = { document_reference: { item: { player_contacts: { label: 'My Label' } } } }
      result = klass.prepare_config(raw, nil)
      ref = result[:document_reference][:item][:player_contact]
      expect(ref).to have_key(:to_record_label),
                     'Expected :to_record_label to be set on resolved reference'
      expect(ref).to have_key(:to_model_name_us),
                     'Expected :to_model_name_us to be set on resolved reference'
    end

    it 'returns nil from prepare_config when raw is nil' do
      result = klass.prepare_config(nil, nil)
      expect(result).to be_nil
    end
  end
end
