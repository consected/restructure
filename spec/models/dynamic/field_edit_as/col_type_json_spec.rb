# frozen_string_literal: true

require 'rails_helper'

# Covers YAML parsing for json/jsonb fields so invalid input cannot silently replace stored data.
RSpec.describe Dynamic::FieldEditAs::ColTypeJson, type: :model do
  describe '.display_value' do
    it 'dumps a non-empty hash to YAML' do
      expect(described_class.display_value({ 'name' => 'Example' })).to eq("name: Example\n")
    end

    it 'dumps a non-empty array to YAML' do
      expect(described_class.display_value(%w[first second])).to eq("- first\n- second\n")
    end

    it 'dumps an empty hash to YAML, distinctly from a blank value' do
      expect(described_class.display_value({})).to eq("--- {}\n")
    end

    it 'dumps an empty array to YAML, distinctly from a blank value' do
      expect(described_class.display_value([])).to eq("--- []\n")
    end

    it 'returns a blank string for nil' do
      expect(described_class.display_value(nil)).to eq('')
    end

    it 'returns a blank string for an empty string' do
      expect(described_class.display_value('')).to eq('')
    end
  end

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

    it 'returns nil for a YAML document representing an empty string, as produced by ' \
       'String.yaml_dump for a blank value and resubmitted unchanged' do
      expect(described_class.persistable_value("--- ''\r\n")).to be_nil
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

  describe 'display then persistable round trip' do
    it 'preserves an empty hash unchanged, distinct from being cleared to nil' do
      displayed = described_class.display_value({})
      expect(described_class.persistable_value(displayed)).to eq({})
    end

    it 'preserves an empty array unchanged, distinct from being cleared to nil' do
      displayed = described_class.display_value([])
      expect(described_class.persistable_value(displayed)).to eq([])
    end

    it 'preserves a blank value as nil (clearing the column)' do
      displayed = described_class.display_value(nil)
      expect(described_class.persistable_value(displayed)).to be_nil
    end

    it 'preserves a non-empty hash unchanged' do
      displayed = described_class.display_value({ 'a' => 1 })
      expect(described_class.persistable_value(displayed)).to eq({ 'a' => 1 })
    end
  end
end
