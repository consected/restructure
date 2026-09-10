# frozen_string_literal: true

require 'rails_helper'

# Spec for Dynamic::FieldEditAs::YamlObject (issue #1269).
#
# This class validates YAML text submitted from the name_starts_with_yaml_object edit
# field for storage in a plain text/varchar database column. Unlike ColTypeJson (used for
# json/jsonb columns), it does NOT parse the value into a Hash/Array for storage - it
# validates the YAML and returns the ORIGINAL TEXT, since the backing column is text.
#
# Tests verify:
# - Valid YAML representing a Hash is returned unchanged (as text).
# - Valid YAML representing an Array is returned unchanged (as text).
# - Blank/nil input returns nil.
# - Malformed YAML raises FphsException.
# - YAML that parses to a scalar (not Hash/Array) raises FphsException.

RSpec.describe Dynamic::FieldEditAs::YamlObject do
  describe '.persistable_value' do
    it 'returns the original YAML text unchanged when it represents a Hash' do
      yaml_text = "key1: value1\nkey2: 42\n"

      expect(described_class.persistable_value(yaml_text)).to eq(yaml_text)
    end

    it 'returns the original YAML text unchanged when it represents an Array' do
      yaml_text = "- first\n- second\n"

      expect(described_class.persistable_value(yaml_text)).to eq(yaml_text)
    end

    it 'returns nil for a blank value' do
      expect(described_class.persistable_value('')).to be_nil
    end

    it 'returns nil for a nil value' do
      expect(described_class.persistable_value(nil)).to be_nil
    end

    it 'raises FphsException for malformed YAML' do
      malformed = "key1: [1, 2\n"

      expect { described_class.persistable_value(malformed) }.to raise_error(FphsException, /cannot parse saved value/)
    end

    it 'raises FphsException when the YAML parses to a scalar rather than a Hash/Array' do
      scalar_yaml = 'just a plain string'

      expect { described_class.persistable_value(scalar_yaml) }.to raise_error(FphsException, /cannot parse saved value/)
    end
  end
end
