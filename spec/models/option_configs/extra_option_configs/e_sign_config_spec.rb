# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for ESignConfig configuration class.
# Verifies source_attribute pattern, configure_attributes for input-only fields,
# COMPUTED_KEYS within document_reference, document_reference wrapping,
# key singularization, model reference resolution, and integration
# with ActivityLogOptions registry.
RSpec.describe 'ExtraOptionConfigs::ESignConfig', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include ExtraOptionConfigsSupport

  before(:all) do
    set_up_extra_options_configs
  end

  let(:klass) { OptionConfigs::ExtraOptionConfigs::ESignConfig }

  describe 'class structure' do
    it 'exists and inherits from BaseConfiguration' do
      expect(klass).to be < OptionConfigs::ExtraOptionConfigs::BaseConfiguration
    end

    it 'declares source_attribute :e_sign' do
      expect(klass.source_attribute).to eq :e_sign
    end

    it 'declares configure_direct with type :hash' do
      expect(klass.option_types[:direct]).to include(:e_sign)
    end

    it 'declares configure_attributes for input-only fields' do
      expect(klass.option_types[:simple]).to include(:create_document, :auto_create_document,
                                                     :document_reference, :title, :intro)
    end

    it 'defines COMPUTED_KEYS for enrichment-only keys within document_reference' do
      expect(klass::COMPUTED_KEYS).to eq %i[to_record_label no_master_association to_model_name_us]
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

  describe 'initialization with configure_attributes' do
    it 'assigns top-level input attributes' do
      raw = {
        create_document: true,
        auto_create_document: false,
        title: 'Test Title',
        intro: 'Test Intro',
        document_reference: { item: { player_contact: { from: :master } } }
      }
      instance = klass.new(raw)
      expect(instance.create_document).to be true
      expect(instance.auto_create_document).to be false
      expect(instance.title).to eq 'Test Title'
      expect(instance.intro).to eq 'Test Intro'
    end

    it 'stores input-only document_reference with computed keys stripped' do
      raw = {
        document_reference: {
          item: {
            player_contact: {
              from: :master,
              label: 'My Label',
              to_record_label: 'COMPUTED',
              no_master_association: false,
              to_model_name_us: 'player_contact'
            }
          }
        }
      }
      instance = klass.new(raw)
      doc_ref = instance.document_reference
      entry = doc_ref[:item][:player_contact]
      expect(entry).to have_key(:from)
      expect(entry).to have_key(:label)
      expect(entry).not_to have_key(:to_record_label)
      expect(entry).not_to have_key(:no_master_association)
      expect(entry).not_to have_key(:to_model_name_us)
    end

    it 'stores enriched hash (with computed keys) on e_sign direct attribute' do
      raw = {
        title: 'Test',
        document_reference: {
          item: {
            player_contact: {
              from: :master,
              to_record_label: 'COMPUTED',
              to_model_name_us: 'player_contact'
            }
          }
        }
      }
      instance = klass.new(raw)
      enriched = instance.e_sign
      entry = enriched[:document_reference][:item][:player_contact]
      expect(entry[:to_record_label]).to eq 'COMPUTED'
      expect(entry[:to_model_name_us]).to eq 'player_contact'
    end
  end
end
