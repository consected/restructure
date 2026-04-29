# frozen_string_literal: true

# Parses and applies the `tracker history initial filters` app configuration,
# which provides regex patterns used to preselect default filter options on
# the tracker history panel (issue #1074).
#
# The expected app configuration value is YAML with the keys:
#   protocols:        '<regex>'
#   sub_processes:    '<regex>'
#   protocol_events:  '<regex>'
#
# Patterns are applied to display names (not numeric IDs). Invalid regex
# values are logged as warnings and result in no preselection for that group.
class TrackerHistoryFilterConfig
  CONFIG_NAME = :tracker_history_initial_filters
  REGEX_KEYS = %i[protocols sub_processes protocol_events].freeze
  LITERAL_KEYS = %i[notes].freeze
  DATE_KEYS = %i[date_from date_to].freeze
  ALLOWED_KEYS = (REGEX_KEYS + LITERAL_KEYS + DATE_KEYS).freeze

  # Return a sanitized hash of regex source strings keyed by the supported
  # multi-select filter group symbols. Unknown keys, blank values and literal
  # (non-regex) keys are omitted. Used for initial preselection of the
  # multi-select filters.
  # @param [User] user
  # @return [Hash{Symbol=>String}]
  def self.config_for(user = nil)
    raw = raw_config(user)
    return {} if raw.blank?

    raw
      .slice(*REGEX_KEYS)
      .each_with_object({}) do |(key, value), acc|
        next if value.blank?

        acc[key] = value.to_s
      end
  end

  # Return the literal initial value for the notes free-text filter, or
  # an empty string when not configured.
  # @param [User] user
  # @return [String]
  def self.notes_initial_for(user = nil)
    raw = raw_config(user)
    raw[:notes].to_s
  end

  # Return resolved initial values for the date_from / date_to filters
  # as `YYYY-MM-DD` strings. Values may be absolute dates (e.g. `2025-02-01`)
  # or relative duration strings such as `-10 days`, `+1 month`, `today()`,
  # which are resolved via `FieldDefaults.calculate_default`.
  # Blank or unparseable values are omitted.
  # @param [User] user
  # @return [Hash{Symbol=>String}]
  def self.date_initial_for(user = nil)
    raw = raw_config(user)
    DATE_KEYS.each_with_object({}) do |key, acc|
      value = raw[key]
      next if value.blank?

      resolved = resolve_date(value)
      acc[key] = resolved if resolved
    end
  end

  # Resolve a configured date value (absolute or relative) to a `YYYY-MM-DD`
  # string, or nil if it cannot be parsed.
  # Relative strings such as `-10 days`, `+1 month`, `today()` are resolved
  # via `FieldDefaults.calculate_default`. Absolute date strings are parsed
  # with `Date.parse`.
  # @param [String] value
  # @return [String, nil]
  def self.resolve_date(value)
    result = FieldDefaults.calculate_default(nil, value.to_s)
    return nil if result.blank?

    case result
    when Date, DateTime, Time, ActiveSupport::TimeWithZone
      result.strftime('%Y-%m-%d')
    when String
      Date.parse(result).strftime('%Y-%m-%d')
    end
  rescue StandardError => e
    Rails.logger.warn(
      "tracker history initial filters: invalid date #{value.inspect} - #{e.message}"
    )
    nil
  end

  # Match the supplied list of names against the regex source pattern.
  # Invalid regex patterns are logged and result in no matches.
  # Blank patterns return an empty result without logging.
  # @param [String, nil] pattern
  # @param [Array<String>] names
  # @return [Array<String>]
  def self.match_names(pattern, names)
    return [] if pattern.blank? || names.blank?

    regex = compile_regex(pattern)
    return [] unless regex

    names.select { |n| n.to_s.match?(regex) }
  end

  # Build per-group preselection lists from the available options.
  # @param [Hash{Symbol=>Array<String>}] options keyed by REGEX_KEYS
  # @param [User] user
  # @return [Hash{Symbol=>Array<String>}]
  def self.initial_selections(options, user = nil)
    config = config_for(user)
    REGEX_KEYS.each_with_object({}) do |key, acc|
      acc[key] = match_names(config[key], options[key] || [])
    end
  end

  # Compile a regex source string, returning nil and logging a warning if invalid.
  # @param [String] pattern
  # @return [Regexp, nil]
  def self.compile_regex(pattern)
    Regexp.new(pattern.to_s)
  rescue RegexpError => e
    Rails.logger.warn(
      "tracker history initial filters: invalid regex #{pattern.inspect} - #{e.message}"
    )
    nil
  end

  # Read the raw YAML hash for the configured user, restricted to allowed keys.
  # @param [User] user
  # @return [Hash{Symbol=>Object}]
  def self.raw_config(user = nil)
    raw = Admin::AppConfiguration.hash_for(CONFIG_NAME, user)
    return {} if raw.blank?

    raw.slice(*ALLOWED_KEYS)
  end
end
