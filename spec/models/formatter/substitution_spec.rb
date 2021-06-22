# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Formatter::Substitution, type: :model do
  it 'substitutes hash values into text' do
    txt = 'This is a simple test: {{int_val}} {{string_key}} {{symbol_key}} "{{blank_val}}" !!!'
    data = {
      int_val: 12_345,
      'string_key' => 'abcdef',
      symbol_key: 'ghijkl',
      blank_val: nil
    }
    res = Formatter::Substitution.substitute txt.dup, data: data, tag_subs: nil

    expect(res).to eq 'This is a simple test: 12345 abcdef ghijkl "" !!!'
  end

  it 'fails if a key is missing from the data' do
    txt = 'This is a simple test: {{int_val}} {{string_key}} {{symbol_key}} "{{blank_val}}" !!!'
    data = {
      int_val: 12_345,
      'string_key' => 'abcdef',
      blank_val: nil
    }

    expect do
      Formatter::Substitution.substitute txt.dup, data: data, tag_subs: nil
    end.to raise_error FphsException
  end
end
