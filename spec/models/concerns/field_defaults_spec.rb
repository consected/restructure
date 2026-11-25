# frozen_string_literal: true

# Tests for FieldDefaults.calculate_default
# - Verifies string substitution, date/time defaults, and tag formatting
# - Verifies that a Hash with a single 'object' key passes the inner value through
#   instead of treating it as a ConditionalActions query (issue #943)
# - Verifies that string values within an 'object' hash are recursively substituted,
#   including through nested hashes and arrays (issue #956)
# - Verifies duration parsing supports weekly units (issue #1593)

require 'rails_helper'

RSpec.describe FieldDefaults, type: :model do
  describe '.duration' do
    it 'parses singular and plural week units while preserving existing units' do
      expect(FieldDefaults.duration('1 week')).to eq 1.week
      expect(FieldDefaults.duration('2 weeks')).to eq 2.weeks
      expect(FieldDefaults.duration('1 day')).to eq 1.day
    end
  end

  describe '.valid_run_at?' do
    ['monday 8:00am', '6:00pm', '2026-05-01 02:00', '2026-05-01T02:00:00', '2026-05-01 02:00 -0500'].each do |value|
      it "accepts #{value.inspect}" do
        expect(FieldDefaults.valid_run_at?(value)).to be true
      end
    end

    it 'accepts time objects and lists of times' do
      expect(FieldDefaults.valid_run_at?(Time.zone.now)).to be true
      expect(FieldDefaults.valid_run_at?(['8:00am', 'sunday 6:00pm'])).to be true
    end

    it 'rejects lists when a single value is required' do
      expect(FieldDefaults.valid_run_at?(['8:00am'], single: true)).to be false
    end

    ['garbage', '', '99:99', 12_345, nil, { a: 1 }, ['8:00am', 'garbage'], []].each do |value|
      it "rejects #{value.inspect}" do
        expect(FieldDefaults.valid_run_at?(value)).to be false
      end
    end
  end

  describe '.recurring_interval' do
    it 'returns positive durations' do
      expect(FieldDefaults.recurring_interval('1 week')).to eq 1.week
    end

    ['0 weeks', '-1 week', '1 fortnight', '', nil, 5, false].each do |value|
      it "returns nil for #{value.inspect}" do
        expect(FieldDefaults.recurring_interval(value)).to be_nil
      end
    end
  end

  it 'gets a default value' do
    val = 'today()'
    res = FieldDefaults.calculate_default(nil, val)
    exp = DateTime.now.iso8601.split('T').first
    expect(res).to eq exp

    data = {
      id: 1,
      something: 'this string',
      data_val: {
        'a' => 3,
        'b' => 2
      }
    }

    val = '{{something}}'
    res = FieldDefaults.calculate_default(data, val)
    exp = data[:something]
    expect(res).to eq exp

    val = 'a {{something}} appears {{id}}'
    res = FieldDefaults.calculate_default(data, val)
    exp = 'a this string appears 1'
    expect(res).to eq exp

    val = '{{data_val}}'
    res = FieldDefaults.calculate_default(data, val)
    exp = '{"a" => 3, "b" => 2}'
    expect(res).to eq exp

    val = '{{{data_val}}}'
    res = FieldDefaults.calculate_default(data, val)
    exp = { 'a' => 3, 'b' => 2 }
    expect(res).to eq exp
  end

  it 'returns the inner object for a Hash with a single object key - issue #943' do
    # When a Hash value has a single key :object, calculate_default should
    # return the inner value directly rather than treating the Hash as
    # a ConditionalActions query. This allows JSONB fields to store
    # arbitrary objects via create_reference / update_reference with: config.
    val = { object: { attr1: 1, attr2: 2 } }
    res = FieldDefaults.calculate_default(nil, val)
    expect(res).to eq({ attr1: 1, attr2: 2 })

    # Also works with a string key 'object'
    val = { 'object' => { 'nested' => 'value', 'count' => 3 } }
    res = FieldDefaults.calculate_default(nil, val)
    expect(res).to eq({ 'nested' => 'value', 'count' => 3 })

    # A Hash with multiple keys (including 'object') is NOT treated as an
    # object passthrough — it remains a ConditionalActions query
    val = { object: { attr1: 1 }, other_key: 'something' }
    # This should NOT return the inner object; it has multiple keys
    # so it falls through to ConditionalActions processing
    expect(val.length).to eq 2
  end

  it 'substitutes string values within the object hash recursively - issue #956' do
    data = {
      id: 100,
      something: 'this string',
      data_val: {
        'a' => 3,
        'b' => 2
      }
    }

    # Simple string substitution inside an object hash
    val = { object: { key1: '{{something}}', key2: 42 } }
    res = FieldDefaults.calculate_default(data, val)
    expect(res).to eq({ key1: 'this string', key2: 42 })

    # Nested hash with string substitutions
    # Note: {{id}} through Formatter::Substitution returns a string
    val = { object: { top: 'literal', nested: { deep: '{{something}}', id_val: '{{id}}' } } }
    res = FieldDefaults.calculate_default(data, val)
    expect(res).to eq({ top: 'literal', nested: { deep: 'this string', id_val: '100' } })

    # Array with string substitutions
    val = { object: ['{{something}}', 'plain', '{{id}}'] }
    res = FieldDefaults.calculate_default(data, val)
    expect(res).to eq(['this string', 'plain', '100'])

    # Mixed nested hash and array
    val = { object: { arr: ['{{something}}', 123], nested: { deep: '{{id}}' } } }
    res = FieldDefaults.calculate_default(data, val)
    expect(res).to eq({ arr: ['this string', 123], nested: { deep: '100' } })

    # Non-string values remain unchanged
    val = { object: { num: 42, bool: true, nothing: nil } }
    res = FieldDefaults.calculate_default(data, val, allow_nil: true)
    expect(res).to eq({ num: 42, bool: true, nothing: nil })

    # Plain object substitution on strings within an array of hashes
    val = { object: [{ name: '{{something}}' }, { count: '{{id}}' }] }
    res = FieldDefaults.calculate_default(data, val)
    expect(res).to eq([{ name: 'this string' }, { count: '100' }])

    # Special defaults like today() work inside object values
    val = { object: { date: 'today()' } }
    res = FieldDefaults.calculate_default(data, val)
    expected_date = DateTime.now.iso8601.split('T').first
    expect(res).to eq({ date: expected_date })

    # Triple-brace substitution returns the actual object for a value
    val = { object: { data: '{{{data_val}}}' } }
    res = FieldDefaults.calculate_default(data, val)
    expect(res).to eq({ data: { 'a' => 3, 'b' => 2 } })

    # String key 'object' also gets substitutions
    val = { 'object' => { 'key' => '{{something}}' } }
    res = FieldDefaults.calculate_default(data, val)
    expect(res).to eq({ 'key' => 'this string' })
  end

  it 'substitutes triple-brace values within object to return plain objects - issue #956' do
    data = {
      id: 100,
      something: 'this string',
      hash_val: { 'a' => 3, 'b' => 2 },
      array_val: [10, 20, 30],
      int_val: 42
    }

    # Triple-brace substitution returning a Hash inside an object hash
    val = { object: { result: '{{{hash_val}}}' } }
    res = FieldDefaults.calculate_default(data, val)
    expect(res).to eq({ result: { 'a' => 3, 'b' => 2 } })

    # Triple-brace substitution returning an Array inside an object hash
    val = { object: { items: '{{{array_val}}}' } }
    res = FieldDefaults.calculate_default(data, val)
    expect(res).to eq({ items: [10, 20, 30] })

    # Triple-brace substitution returning an Integer inside an object hash
    val = { object: { count: '{{{int_val}}}' } }
    res = FieldDefaults.calculate_default(data, val)
    expect(res).to eq({ count: 42 })

    # Triple-brace substitution within an array
    val = { object: ['{{{hash_val}}}', '{{{array_val}}}', '{{{int_val}}}'] }
    res = FieldDefaults.calculate_default(data, val)
    expect(res).to eq([{ 'a' => 3, 'b' => 2 }, [10, 20, 30], 42])

    # Mixed triple-brace and double-brace within the same object
    val = { object: { name: '{{something}}', data: '{{{hash_val}}}', num: '{{{int_val}}}' } }
    res = FieldDefaults.calculate_default(data, val)
    expect(res).to eq({ name: 'this string', data: { 'a' => 3, 'b' => 2 }, num: 42 })
  end
end
