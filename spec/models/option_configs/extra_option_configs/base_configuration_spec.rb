# frozen_string_literal: true

require 'rails_helper'

# Tests for shared model-reference resolution in BaseConfiguration.
#
# Coverage:
# - Resolved, missing, and definition-less classes
# - Import suppression and nil-parent tolerance
# - ExtraOptions recording, predicate, and per-config clearing APIs
RSpec.describe OptionConfigs::ExtraOptionConfigs::BaseConfiguration, type: :model do
  let(:parent) { OptionConfigs::ExtraOptions.allocate }

  before do
    allow(Admin::AppTypeImport).to receive(:import_in_progress?).and_return(false)
  end

  describe '.resolve_model_reference_class' do
    it 'returns a resolved class without recording it' do
      resolved_class = Class.new
      allow(ModelReference).to receive(:to_record_class_for_type).with(:resolved_target).and_return(resolved_class)

      expect(described_class.resolve_model_reference_class(:resolved_target, parent)).to be(resolved_class)
      expect(parent.unresolved_model_references).to be_empty
    end

    it 'returns nil and records a missing class on the parent' do
      allow(ModelReference).to receive(:to_record_class_for_type).with(:missing_target).and_return(nil)

      expect(described_class.resolve_model_reference_class(:missing_target, parent)).to be_nil
      expect(parent.unresolved_model_references).to eq(described_class => [:missing_target])
    end

    it 'treats a class with no definition as unresolved' do
      unresolved_class = Class.new do
        def self.definition
          nil
        end
      end
      allow(ModelReference).to receive(:to_record_class_for_type).with(:definitionless_target).and_return(unresolved_class)

      expect(described_class.resolve_model_reference_class(:definitionless_target, parent)).to be_nil
      expect(parent.unresolved_model_references).to eq(described_class => [:definitionless_target])
    end

    it 'does not record unresolved classes during an app type import' do
      allow(Admin::AppTypeImport).to receive(:import_in_progress?).and_return(true)
      allow(ModelReference).to receive(:to_record_class_for_type).with(:import_target).and_return(nil)

      expect(described_class.resolve_model_reference_class(:import_target, parent)).to be_nil
      expect(parent.unresolved_model_references).to be_empty
    end

    it 'tolerates a nil parent' do
      allow(ModelReference).to receive(:to_record_class_for_type).with(:missing_target).and_return(nil)

      expect { described_class.resolve_model_reference_class(:missing_target, nil) }.not_to raise_error
    end
  end

  describe 'unresolved model reference tracking' do
    it 'records names by configuration class and clears only that class' do
      references_class = OptionConfigs::ExtraOptionConfigs::References
      parent.record_unresolved_model_reference(described_class, :first_target)
      parent.record_unresolved_model_reference(references_class, :second_target)

      expect(parent.unresolved_model_references?).to be true

      parent.clear_unresolved_model_references(described_class)

      expect(parent.unresolved_model_references).not_to have_key(described_class)
      expect(parent.unresolved_model_references[references_class]).to eq([:second_target])
      expect(parent.unresolved_model_references?).to be true

      parent.clear_unresolved_model_references(references_class)
      expect(parent.unresolved_model_references?).to be false
    end

    it 'keeps tracking state out of YAML-settable attributes' do
      expect(OptionConfigs::ExtraOptions.key_attributes).not_to include(:unresolved_model_references)
      expect(parent).not_to respond_to(:unresolved_model_references=)
    end
  end
end
