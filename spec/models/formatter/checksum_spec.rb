require 'rails_helper'

RSpec.describe Formatter::Checksum, type: :model do
  include ModelSupport
  include PlayerContactSupport

  it 'generates a valid checksum' do
    expect(Formatter::Checksum.checksum(123)).to eq 0
    expect(Formatter::Checksum.checksum(456)).to eq 4
    expect(Formatter::Checksum.checksum(7_992_739_871)).to eq 3
  end

  it 'formats a number with a checksum' do
    expect(Formatter::Checksum.format(123)).to eq '1230'
    expect(Formatter::Checksum.format(456)).to eq '4564'
    expect(Formatter::Checksum.format(7_992_739_871)).to eq '79927398713'
  end

  it 'validates a number' do
    expect(Formatter::Checksum.number_valid?('1230')).to be true
    expect(Formatter::Checksum.number_valid?('1239')).to be false
    expect(Formatter::Checksum.number_valid?('4564')).to be true
    expect(Formatter::Checksum.number_valid?('4563')).to be false
    expect(Formatter::Checksum.number_valid?('79927398713')).to be true
    expect(Formatter::Checksum.number_valid?(79_927_398_713)).to be true
    expect(Formatter::Checksum.number_valid?('79927398710')).to be false
    expect(Formatter::Checksum.number_valid?(79_927_398_710)).to be false
    expect(Formatter::Checksum.number_valid?('79927398711')).to be false
    expect(Formatter::Checksum.number_valid?('79927398712')).to be false
    expect(Formatter::Checksum.number_valid?('79927398714')).to be false
    expect(Formatter::Checksum.number_valid?('79927398715')).to be false
    expect(Formatter::Checksum.number_valid?('79927398716')).to be false
    expect(Formatter::Checksum.number_valid?('79927398717')).to be false
    expect(Formatter::Checksum.number_valid?('79927398718')).to be false
    expect(Formatter::Checksum.number_valid?('79927398719')).to be false
  end
end
