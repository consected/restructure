# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'StandardAuthentication', type: :model do
  TestRegex = '^(?=.*[a-zA-Z])(?=.*[0-9]).{6,}$'
  TestRegex2 = '^.*(?=.{8,})(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).*$'

  def unfreeze_config
    conf = Settings::PasswordConfig.deep_dup
    change_setting('PasswordConfig', conf)
  end

  before :all do
    unfreeze_config
  end

  it 'checks no defined regex is ignored' do
    r = User.password_config[:regex]
    expect(r).to be_blank

    expect(User.password_regex_matched?('')).to be true
  end

  it 'checks password matches a configured regex' do
    User.password_config[:regex] = TestRegex

    expect(User.password_regex_matched?('')).to be false
    expect(User.password_regex_matched?('abcdef')).to be false
    expect(User.password_regex_matched?('abc3DE')).to be true

    User.password_config[:regex] = TestRegex2
    expect(User.password_regex_matched?('')).to be false
    expect(User.password_regex_matched?('abcdefgh123123')).to be false
    expect(User.password_regex_matched?('abc3DE')).to be false
    expect(User.password_regex_matched?('abc3DE45')).to be true
  end

  it 'checks entropy of a password' do
    expect(User.calculate_entropy_strength('abcdefghi')).to be > 0
  end

  it 'validates a password strength with multiple rules' do
    result = {}
    User.password_config[:regex] = nil
    User.password_config[:min_entropy] = 10
    res = User.password_strong_enough('abc', result: result)
    expect(res).to be false
    expect(result[:test]).to eq :entropy

    res = User.password_strong_enough('abc kasjdhfiuy qwer iuwqyka jsdhjfdk hasdfksyihkjasdhfkashfd', result: result)
    expect(res).to be true

    User.password_config[:regex] = TestRegex
    msg = User.password_config[:regex_requirements] = 'Minimum 6 characters, one letter and one number'
    res = User.password_strong_enough('abc kasjdhfiuy qwer iuwqyka jsdhjfdk hasdfksyihkjasdhfkashfd', result: result)
    expect(res).to be false
    expect(result[:test]).to eq :regex
    expect(result[:reason]).to eq "is not complex enough. #{msg}"

    res = User.password_strong_enough('1 abc kasjdhfiuy qwer iuwqyka jsdhjfdk hasdfksyihkjasdhfkashfd', result: result)
    expect(res).to be true

    User.password_config[:min_entropy] = 0
    res = User.password_strong_enough('a', result: result)
    expect(res).to be false
    expect(result[:test]).to eq :regex
  end
end
