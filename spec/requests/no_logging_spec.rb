# frozen_string_literal: true

require 'rails_helper'

describe 'no logging in production' do
  it 'should log if the environment variable is set' do
    ENV['FPHS_USE_LOGGER'] = 'TRUE'

    d = DateTime.now
    s = "This is a test of the logger at #{d}"
    Rails.logger.warn s
    log = Rails.root.join('log/test.log')
    n = `grep '#{s}' #{log}`
    n = n.gsub("\n", '')
    expect(n).to match(s)
  end

  it 'should not log if the environment variable is not set' do
    ENV['FPHS_USE_LOGGER'] = nil
    old_logger = Rails.logger
    Rails.logger = DoNothingLogger.new

    d = DateTime.now
    s = "This is a test of the logger being disabled at #{d}"
    Rails.logger.warn s
    log = Rails.root.join('log/test.log')
    n = `grep '#{s}' #{log}`
    n = n.gsub("\n", '')
    Rails.logger = old_logger
    expect(n).not_to match(/#{s}/)
  end
end
