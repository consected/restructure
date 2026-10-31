# frozen_string_literal: true

# Purpose: Verify notification phone normalization and contact lookup candidates for configured countries.
require 'rails_helper'

RSpec.describe 'Messaging::PhoneNumberMatcher' do
  let(:matcher_class) { Messaging.const_get(:PhoneNumberMatcher) }

  describe '#national' do
    [
      ['E.164 US number', '+16175551212', '1', '1', '6175551212'],
      ['formatted US number', '(617)555-1212', '1', '1', '6175551212'],
      ['unformatted US number', '6175551212', '1', '1', '6175551212'],
      ['11-digit US contact typo', '16175551212', '1', '1', '6175551212'],
      ['E.164 UK number', '+447700900123', '44', '0', '7700900123'],
      ['UK number without plus keeps country code', '447700900123', '44', '0', '447700900123'],
      ['UK national number removes trunk prefix', '07700900123', '44', '0', '7700900123'],
      ['blank value', ' ', '1', '1', nil],
      ['nil value', nil, '1', '1', nil],
      ['garbage value', 'not a phone number', '1', '1', nil],
      ['number containing only the E.164 country code', '+44', '44', '0', nil],
      ['number shorter than trunk prefix', '1', '44', '12', '1'],
      ['number equal to trunk prefix', '0', '44', '0', '0']
    ].each do |description, value, country_code, trunk_number, expected|
      it "normalizes #{description}" do
        matcher = matcher_class.new(country_code:, trunk_number:)

        expect(matcher.national(value)).to eq expected
      end
    end
  end

  describe '#candidates' do
    it 'uses only digits for foreign E.164 numbers and preserves other candidate rules' do
      [
        ['foreign E.164 number with US defaults', '+4732123456', '1', '1', %w[4732123456]],
        ['foreign E.164 number with UK defaults', '+14155551212', '44', '0', %w[14155551212]],
        ['E.164 number with configured country code', '+16175551212', '1', '1', %w[6175551212 16175551212]],
        ['UK E.164 number with configured country code', '+447700900123', '44', '0',
         %w[7700900123 07700900123 447700900123]],
        ['formatted local number', '(617) 555-1212', '1', '1', %w[6175551212 16175551212]],
        ['digits-only value without a plus sign', '4732123456', '1', '1', %w[4732123456 14732123456]],
        ['blank value', '---', '44', '0', []]
      ].each do |description, value, country_code, trunk_number, expected|
        matcher = matcher_class.new(country_code:, trunk_number:)

        expect(matcher.candidates(value)).to eq(expected), description
      end
    end

    it 'ignores a phone extension when building lookup candidates' do
      matcher = matcher_class.new(country_code: '1', trunk_number: '1')

      expect(matcher.candidates('(516) 555-0102 ext. 77')).to eq %w[5165550102 15165550102]
    end
  end

  describe 'server defaults' do
    it 'uses country code 1 and trunk number 1 by default' do
      expect(Settings::DefaultPhoneCountryCode).to eq '1'
      expect(Settings::DefaultPhoneTrunkNumber).to eq '1'
      expect(Settings::AppSettingsVars).to include('DefaultPhoneCountryCode', 'DefaultPhoneTrunkNumber')
    end
  end
end
