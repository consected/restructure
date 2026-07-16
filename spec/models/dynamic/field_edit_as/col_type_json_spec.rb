# frozen_string_literal: true

require 'rails_helper'

# Covers YAML parsing for json/jsonb fields so invalid input cannot silently replace stored data.
RSpec.describe Dynamic::FieldEditAs::ColTypeJson, type: :model do
  describe '.persistable_value' do
    it 'returns a hash for a YAML mapping' do
      expect(described_class.persistable_value("name: Example\nenabled: true\n")).to eq(
        { 'name' => 'Example', 'enabled' => true }
      )
    end

    it 'returns an array for a YAML sequence' do
      expect(described_class.persistable_value("- first\n- second\n")).to eq(%w[first second])
    end

    it 'returns nil for blank input so the field can be cleared' do
      expect(described_class.persistable_value('')).to be_nil
    end

    [
      ['malformed YAML', "name: [\n"],
      ['a YAML alias rejected by safe_load', "first: &shared value\nsecond: *shared\n"],
      ['a scalar YAML value', "example\n"],
      ['a null YAML value', "null\n"],
      ['a false YAML value', "false\n"]
    ].each do |description, yaml|
      it "raises FphsException for #{description}" do
        expect { described_class.persistable_value(yaml) }.to raise_error(
          FphsException,
          /col_type_json: cannot parse saved value/
        )
      end
    end
  end
end
