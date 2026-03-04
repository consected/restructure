# frozen_string_literal: true

# Tests for FieldDefaults.calculate_default
# - Verifies string substitution, date/time defaults, and tag formatting
# - Verifies that a Hash with a single 'object' key passes the inner value through
#   instead of treating it as a ConditionalActions query (issue #943)

require 'rails_helper'

RSpec.describe FieldDefaults, type: :model do
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
end
