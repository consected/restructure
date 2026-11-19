# frozen_string_literal: true

# Purpose: when a dynamic definition reuses its already-generated implementation class
# (for example after the definition record was re-created with a new id), the class must
# point at the current definition record rather than a stale id that has no cached definition.
require 'rails_helper'

RSpec.describe DynamicModel, type: :model do
  let(:definition) { described_class.active.detect { |d| d.implementation_class_defined?(DynamicModel) } }

  it 'repoints a reused implementation class at the current definition id' do
    skip 'No active dynamic model with a generated class' unless definition

    klass = definition.implementation_class
    original_id = klass.definition_id
    original_cache_entry = described_class.definition_cache[definition.id]

    klass.definition_id = -1
    expect(klass.definition).to be_nil

    definition.generate_model

    expect(klass.definition_id).to eq definition.id
    expect(klass.definition).to equal definition
  ensure
    klass&.definition_id = original_id
    if original_cache_entry
      described_class.definition_cache[definition.id] = original_cache_entry
    elsif definition
      described_class.definition_cache.delete(definition.id)
    end
  end
end
