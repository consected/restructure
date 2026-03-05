# frozen_string_literal: true

module Messaging
  #
  # Generate RFC 5545 compliant VCALENDAR/VEVENT .ics content
  # for email notification attachments.
  # Supports METHOD:REQUEST (invitation) and METHOD:CANCEL (cancellation).
  #
  # @example
  #   config = {
  #     'method' => 'REQUEST',
  #     'summary' => 'Meeting Title',
  #     'description' => 'Meeting notes',
  #     'location' => 'Room 101',
  #     'dtstart' => '2026-04-01 10:00:00',
  #     'dtend' => '2026-04-01 11:00:00',
  #     'organizer' => 'organizer@example.com',
  #     'uid' => 'unique-id@restructure',
  #     'sequence' => 0
  #   }
  #   invite = Messaging::CalendarInvite.new(config)
  #   ics_content = invite.generate
  class CalendarInvite
    ValidMethods = %w[REQUEST CANCEL].freeze

    attr_reader :config

    # @param [Hash] config - calendar invite configuration with string keys
    def initialize(config)
      @config = config
    end

    #
    # Generate an RFC 5545 compliant VCALENDAR string with a VEVENT
    # @return [String] the .ics file content
    def generate
      apply_defaults!
      validate_config!

      lines = []
      lines << 'BEGIN:VCALENDAR'
      lines << 'VERSION:2.0'
      lines << 'PRODID:-//ReStructure//MessageNotification//EN'
      lines << "METHOD:#{ical_method}"
      lines << 'BEGIN:VEVENT'
      lines << "DTSTART:#{format_datetime(config['dtstart'])}"
      lines << "DTEND:#{format_datetime(resolved_dtend)}"
      lines << "DTSTAMP:#{format_datetime(Time.current)}"
      lines << "UID:#{config['uid']}"
      lines << "SEQUENCE:#{config['sequence'] || 0}"
      lines << "SUMMARY:#{config['summary']}"
      lines << "DESCRIPTION:#{config['description']}" if config['description']
      lines << "LOCATION:#{config['location']}" if config['location']
      lines << "ORGANIZER:mailto:#{config['organizer']}"
      lines << 'STATUS:CANCELLED' if ical_method == 'CANCEL'
      lines << 'END:VEVENT'
      lines << 'END:VCALENDAR'

      lines.join("\r\n") + "\r\n"
    end

    private

    #
    # Apply sensible defaults to config fields that were not provided.
    # - method defaults to 'REQUEST'
    # - uid defaults to a generated UUID@restructure
    # - dtend is calculated from dtstart + duration if absent but duration is provided.
    #   Duration is parsed by FieldDefaults.duration (e.g. "90 minutes", "1 hour").
    # @return [void]
    def apply_defaults!
      config['method'] = 'REQUEST' if config['method'].blank?
      config['uid'] = "#{SecureRandom.uuid}@restructure" if config['uid'].blank?

      return unless config['dtend'].blank? && config['duration'].present?

      dur = FieldDefaults.duration(config['duration'].to_s)
      raise FphsException, "CalendarInvite: invalid duration '#{config['duration']}'" unless dur

      start_time = parse_datetime(config['dtstart'])
      config['dtend'] = (start_time + dur).iso8601
    end

    #
    # The iCalendar method (REQUEST or CANCEL), uppercased
    # @return [String]
    def ical_method
      config['method']&.upcase
    end

    #
    # The resolved dtend value, preferring the explicit dtend over duration-calculated value
    # @return [String]
    def resolved_dtend
      config['dtend']
    end

    #
    # Parse a datetime value into a Time object
    # @param [Time, DateTime, Date, String] value
    # @return [Time]
    def parse_datetime(value)
      case value
      when Time, DateTime
        value.utc
      when Date
        value.to_time.utc
      when String
        Time.zone.parse(value).utc
      else
        raise FphsException, "CalendarInvite: unsupported datetime type #{value.class}"
      end
    end

    #
    # Format a datetime value to UTC YYYYMMDDTHHMMSSZ format
    # Accepts Time, DateTime, Date, or parseable String
    # @param [Time, DateTime, Date, String] value
    # @return [String] formatted as YYYYMMDDTHHMMSSZ
    def format_datetime(value)
      parse_datetime(value).strftime('%Y%m%dT%H%M%SZ')
    end

    #
    # Validate that required config fields are present and method is valid
    def validate_config!
      unless ical_method.in?(ValidMethods)
        raise FphsException, "CalendarInvite: method must be one of #{ValidMethods.join(', ')}, got #{config['method']}"
      end

      %w[summary dtstart organizer].each do |field|
        raise FphsException, "CalendarInvite: #{field} is required" if config[field].blank?
      end

      return unless config['dtend'].blank? && config['duration'].blank?

      raise FphsException, 'CalendarInvite: dtend or duration is required'
    end
  end
end
