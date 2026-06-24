# frozen_string_literal: true

# Tests for the Resources::Models.find_model / find_model! safe-lookup methods.
#
# These methods provide an allow-listed way to resolve a class name string to
# the registered model class without invoking Object#constantize on
# user-influenced input. Only models that have been registered in the
# Resources::Models registry are resolvable, eliminating the constantize-as-RCE
# attack surface.

require 'rails_helper'

RSpec.describe Resources::Models, type: :model do
  describe '.find_model' do
    it 'returns the model when given the canonical resource_name (plural snake double-underscore)' do
      expect(described_class.find_model('masters')).to eq(Master)
    end

    it 'returns the model when given the singular resource_item_name' do
      entry = Resources::Models.resources.values.find do |r|
        r[:resource_item_name] && r[:resource_item_name] != r[:resource_name]
      end
      skip 'No model with a distinct resource_item_name registered' unless entry

      expect(described_class.find_model(entry[:resource_item_name].to_s)).to eq(entry[:model])
    end

    it 'returns the model when given the fully qualified Ruby class name with :: separators' do
      expect(described_class.find_model('Master')).to eq(Master)
    end

    it 'returns the model when given the camelized namespace with / separators' do
      # ns_camelize produces forms like "DynamicModel/ContactInfo" before constantize
      reg = described_class.find_by(type: :dynamic_model)
      skip 'No dynamic model registered in this test context' unless reg

      class_name = reg[:class_name]
      slashed = class_name.gsub('::', '/')
      expect(described_class.find_model(slashed)).to eq(reg[:model])
    end

    it 'returns nil for an unknown / unregistered class name' do
      expect(described_class.find_model('NotARealClass')).to be_nil
      expect(described_class.find_model('not_a_real_thing')).to be_nil
    end

    it 'returns nil for blank input' do
      expect(described_class.find_model(nil)).to be_nil
      expect(described_class.find_model('')).to be_nil
    end

    it 'does NOT invoke Object#constantize on the input string' do
      # If constantize were called we would either resolve Kernel (existing top-level
      # constant) or hit a NameError. Either way the registry-only path must return nil.
      expect_any_instance_of(String).not_to receive(:constantize)
      expect(described_class.find_model('Kernel')).to be_nil
      expect(described_class.find_model('Object')).to be_nil
      expect(described_class.find_model('File')).to be_nil
    end

    it 'is not fooled by string forms that constantize would otherwise resolve' do
      # Even injection-style payloads that look like valid Ruby constants must not
      # resolve to anything outside the allow-listed registry.
      expect(described_class.find_model('ActiveRecord::Base')).to be_nil
      expect(described_class.find_model('Rails::Application')).to be_nil
    end
  end

  describe '.find_model!' do
    it 'returns the model for a registered class name' do
      expect(described_class.find_model!('masters')).to eq(Master)
    end

    it 'raises FphsException for an unknown class name' do
      expect { described_class.find_model!('NotARealClass') }
        .to raise_error(FphsException, /not a recognized|unknown|invalid/i)
    end

    it 'raises FphsException for blank input' do
      expect { described_class.find_model!(nil) }
        .to raise_error(FphsException)
    end
  end
end
