# frozen_string_literal: true

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
    exp = '{"a"=>3, "b"=>2}'
    expect(res).to eq exp

    val = '{{{data_val}}}'
    res = FieldDefaults.calculate_default(data, val)
    exp = { 'a' => 3, 'b' => 2 }
    expect(res).to eq exp
  end
end
