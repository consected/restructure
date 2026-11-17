# frozen_string_literal: true

# Tests for Messaging::CalendarInvite service class (issue #953)
# Validates RFC 5545 compliant VCALENDAR/VEVENT .ics generation
# supporting METHOD:REQUEST (invitation) and METHOD:CANCEL (cancellation).
# Tests cover: defaults, case insensitivity, duration option, validation errors,
# optional field omission, and (issue #1302) Date-typed dtstart/dtend input via
# the parse_datetime `Date` branch.

require 'rails_helper'

RSpec.describe Messaging::CalendarInvite, type: :model do
  let(:valid_config) do
    {
      'method' => 'REQUEST',
      'summary' => 'Study Review Meeting',
      'description' => 'Discuss study progress',
      'location' => 'Conference Room A',
      'dtstart' => '2026-04-01 10:00:00',
      'dtend' => '2026-04-01 11:00:00',
      'organizer' => 'organizer@example.com',
      'uid' => 'test-123@restructure',
      'sequence' => 0
    }
  end

  # Minimal config relying on defaults for method, uid, and sequence
  let(:minimal_config) do
    {
      'summary' => 'Quick Sync',
      'dtstart' => '2026-04-01 10:00:00',
      'dtend' => '2026-04-01 11:00:00',
      'organizer' => 'organizer@example.com'
    }
  end

  describe '#generate' do
    it 'generates valid RFC 5545 VCALENDAR with METHOD:REQUEST for an invitation' do
      invite = described_class.new(valid_config)
      ics_content = invite.generate

      expect(ics_content).to include('BEGIN:VCALENDAR')
      expect(ics_content).to include('VERSION:2.0')
      expect(ics_content).to include('PRODID:')
      expect(ics_content).to include('METHOD:REQUEST')
      expect(ics_content).to include('BEGIN:VEVENT')
      expect(ics_content).to include('SUMMARY:Study Review Meeting')
      expect(ics_content).to include('DESCRIPTION:Discuss study progress')
      expect(ics_content).to include('LOCATION:Conference Room A')
      expect(ics_content).to include('UID:test-123@restructure')
      expect(ics_content).to include('SEQUENCE:0')
      expect(ics_content).to include('ORGANIZER:mailto:organizer@example.com')
      expect(ics_content).to include('END:VEVENT')
      expect(ics_content).to include('END:VCALENDAR')
    end

    it 'generates valid RFC 5545 VCALENDAR with METHOD:CANCEL for a cancellation' do
      cancel_config = valid_config.merge('method' => 'CANCEL')
      invite = described_class.new(cancel_config)
      ics_content = invite.generate

      expect(ics_content).to include('BEGIN:VCALENDAR')
      expect(ics_content).to include('METHOD:CANCEL')
      expect(ics_content).to include('BEGIN:VEVENT')
      expect(ics_content).to include('STATUS:CANCELLED')
      expect(ics_content).to include('UID:test-123@restructure')
      expect(ics_content).to include('END:VEVENT')
      expect(ics_content).to include('END:VCALENDAR')
    end

    it 'formats datetime values to UTC YYYYMMDDTHHMMSSZ format' do
      config = valid_config.merge(
        'dtstart' => '2026-06-15 14:30:00',
        'dtend' => '2026-06-15 16:00:00'
      )
      invite = described_class.new(config)
      ics_content = invite.generate

      expect(ics_content).to include('DTSTART:20260615T143000Z')
      expect(ics_content).to include('DTEND:20260615T160000Z')
    end

    it 'auto-generates DTSTAMP with current UTC time' do
      freeze_time = Time.utc(2026, 3, 5, 12, 0, 0)
      allow(Time).to receive(:current).and_return(freeze_time)

      invite = described_class.new(valid_config)
      ics_content = invite.generate

      expect(ics_content).to include('DTSTAMP:20260305T120000Z')
    end

    # Regression coverage for issue #1302 (config.active_support.to_time_preserves_timezone).
    # #parse_datetime's `Date` branch calls `value.to_time.utc`. Under :zone, `Date#to_time`
    # is unaffected (only ActiveSupport::TimeWithZone#to_time changes behaviour), but this
    # confirms the whole chain still produces a correct UTC ical timestamp when a Date object
    # (rather than a String) is supplied for dtstart/dtend. `Date#to_time` converts using the
    # server's local system timezone (not Rails' `Time.zone`), so the expected value is
    # computed the same way rather than hardcoded, keeping the spec environment-independent.
    it 'accepts a Date object for dtstart/dtend and formats it to UTC' do
      date = Date.new(2026, 6, 15)
      config = valid_config.merge('dtstart' => date, 'dtend' => date)
      invite = described_class.new(config)
      ics_content = invite.generate

      expected = date.to_time.utc.strftime('%Y%m%dT%H%M%SZ')
      expect(ics_content).to include("DTSTART:#{expected}")
      expect(ics_content).to include("DTEND:#{expected}")
    end

    context 'with defaults' do
      it 'defaults method to REQUEST when not provided' do
        invite = described_class.new(minimal_config)
        ics_content = invite.generate

        expect(ics_content).to include('METHOD:REQUEST')
        expect(ics_content).not_to include('STATUS:CANCELLED')
      end

      it 'defaults uid to a generated value when not provided' do
        invite = described_class.new(minimal_config)
        ics_content = invite.generate

        # Should have a UID line with some auto-generated value
        expect(ics_content).to match(/UID:.+@restructure/)
      end

      it 'defaults sequence to 0 when not provided' do
        invite = described_class.new(minimal_config)
        ics_content = invite.generate

        expect(ics_content).to include('SEQUENCE:0')
      end
    end

    context 'with case-insensitive method' do
      it 'accepts lowercase method and uppercases it in output' do
        config = valid_config.merge('method' => 'request')
        invite = described_class.new(config)
        ics_content = invite.generate

        expect(ics_content).to include('METHOD:REQUEST')
      end

      it 'accepts mixed-case method and uppercases it in output' do
        config = valid_config.merge('method' => 'Cancel')
        invite = described_class.new(config)
        ics_content = invite.generate

        expect(ics_content).to include('METHOD:CANCEL')
        expect(ics_content).to include('STATUS:CANCELLED')
      end
    end

    context 'with duration option' do
      it 'calculates dtend from dtstart + duration string when dtend is absent' do
        config = minimal_config.except('dtend').merge(
          'duration' => '90 minutes'
        )
        invite = described_class.new(config)
        ics_content = invite.generate

        # dtstart is 2026-04-01 10:00:00, + 90 minutes = 11:30:00
        expect(ics_content).to include('DTSTART:20260401T100000Z')
        expect(ics_content).to include('DTEND:20260401T113000Z')
      end

      it 'supports hour-based duration strings' do
        config = minimal_config.except('dtend').merge(
          'duration' => '2 hours'
        )
        invite = described_class.new(config)
        ics_content = invite.generate

        # dtstart is 2026-04-01 10:00:00, + 2 hours = 12:00:00
        expect(ics_content).to include('DTEND:20260401T120000Z')
      end

      it 'ignores duration when dtend is explicitly provided' do
        config = valid_config.merge('duration' => '90 minutes')
        invite = described_class.new(config)
        ics_content = invite.generate

        # dtend should be 11:00 (from config), not 11:30 (from duration)
        expect(ics_content).to include('DTEND:20260401T110000Z')
      end

      it 'raises FphsException for an invalid duration string' do
        config = minimal_config.except('dtend').merge('duration' => 'bogus')
        invite = described_class.new(config)

        expect { invite.generate }.to raise_error(FphsException, /invalid duration/)
      end
    end

    context 'with optional fields omitted' do
      it 'omits DESCRIPTION when not provided' do
        config = valid_config.except('description')
        invite = described_class.new(config)
        ics_content = invite.generate

        expect(ics_content).not_to include('DESCRIPTION:')
      end

      it 'omits LOCATION when not provided' do
        config = valid_config.except('location')
        invite = described_class.new(config)
        ics_content = invite.generate

        expect(ics_content).not_to include('LOCATION:')
      end
    end
  end

  describe 'validation' do
    it 'raises FphsException for an invalid method value' do
      config = valid_config.merge('method' => 'PUBLISH')
      invite = described_class.new(config)

      expect { invite.generate }.to raise_error(FphsException, /method must be one of/)
    end

    it 'raises FphsException when summary is missing' do
      config = valid_config.except('summary')
      invite = described_class.new(config)

      expect { invite.generate }.to raise_error(FphsException, /summary is required/)
    end

    it 'raises FphsException when dtstart is missing' do
      config = valid_config.except('dtstart')
      invite = described_class.new(config)

      expect { invite.generate }.to raise_error(FphsException, /dtstart is required/)
    end

    it 'raises FphsException when organizer is missing' do
      config = valid_config.except('organizer')
      invite = described_class.new(config)

      expect { invite.generate }.to raise_error(FphsException, /organizer is required/)
    end

    it 'does not raise when dtend is absent but duration is provided' do
      config = valid_config.except('dtend').merge('duration' => '60 minutes')
      invite = described_class.new(config)

      expect { invite.generate }.not_to raise_error
    end

    it 'raises FphsException when both dtend and duration are missing' do
      config = valid_config.except('dtend')
      invite = described_class.new(config)

      expect { invite.generate }.to raise_error(FphsException, /dtend or duration is required/)
    end
  end
end
