# frozen_string_literal: true

module Formatter
  # NOTE: if additional formatters are added here, they also need matching javascript
  # in _fpa_tag_formatter
  class TagFormatter
    attr_accessor :current_user, :tag_name, :data

    ValidOps = %w[
      capitalize
      titleize
      uppercase
      lowercase
      underscore
      hyphenate
      id_hyphenate
      id_underscore
      initial
      first
      age
      date
      date_time
      date_time_with_zone
      date_time_show_zone
      time
      time_ignore_zone
      time_show_zone
      time_with_zone
      time_sec
      dicom_datetime
      dicom_date
      redcap_date
      iso8601_datetime
      join_with_space
      join_with_comma
      join_with_csv
      join_with_semicolon
      join_with_pipe
      join_with_dot
      join_with_at
      join_with_slash
      join_with_newline
      join_with_2newlines
      compact
      sort
      sort_reverse
      uniq
      markdown_list
      html_list
      plaintext
      strip
      split_space
      split_lines
      split_comma
      split_csv
      split_semicolon
      split_pipe
      split_dot
      split_at
      split_slash
      markup
      yaml
      json
      ignore_missing
      last
      no_html_tag
      general_selection_label
      parse_json
      parse_yaml
    ].freeze

    #
    # Format a tag value with the named formatter operation
    # @param [String] operation - formatter name
    # @param [String] curr_val - tag value
    # @param [Object] orig_val - tag value in its original form (may not be a string)
    # @param [User] current_user - current user associated with the data
    # @param [String] tag_name - tag name returning value being formatted
    # @param [Object] data - the original dataset the tag was retrieved from
    # @return [String|nil] result
    def self.format_with(operation, curr_val, orig_val, current_user = nil, tag_name = nil, data = nil)
      processor = new(current_user: current_user, tag_name: tag_name, data: data)

      processor.process(operation, curr_val, orig_val)
    end

    def initialize(current_user: nil, tag_name: nil, data: nil)
      self.current_user = current_user
      self.tag_name = tag_name
      self.data = data
    end

    def process(operation, curr_val, orig_val)
      if operation.in?(ValidOps)
        send operation, curr_val, orig_val
      elsif curr_val.is_a?(Array) && operation.to_i.to_s == operation
        curr_val[operation.to_i]
      elsif operation.to_i != 0
        curr_val[0..operation.to_i]
      else
        curr_val
      end
    end

    #
    # Converts the first character to uppercase and the rest to lowercase
    # @param [String] res - the string value to format
    # @return [String] capitalized string
    def capitalize(res, _orig_val)
      res.capitalize
    end

    #
    # Converts each word's first character to uppercase (title case)
    # @param [String] res - the string value to format
    # @return [String] title case string
    def titleize(res, _orig_val)
      res.captionize
    end

    #
    # Converts all characters to uppercase
    # @param [String] res - the string value to format
    # @return [String] uppercase string
    def uppercase(res, _orig_val)
      res.upcase
    end

    #
    # Converts all characters to lowercase
    # @param [String] res - the string value to format
    # @return [String] lowercase string
    def lowercase(res, _orig_val)
      res.downcase
    end

    #
    # Converts camelCase or spaces to snake_case format
    # @param [String] res - the string value to format
    # @return [String] underscored string
    def underscore(res, _orig_val)
      res.underscore
    end

    #
    # Converts spaces to hyphens
    # @param [String] res - the string value to format
    # @return [String] hyphenated string
    def hyphenate(res, _orig_val)
      res.hyphenate
    end

    #
    # Converts to a hyphenated identifier (alphanumeric with hyphens, ending with hyphen)
    # @param [String] res - the string value to format
    # @return [String] hyphenated identifier
    def id_hyphenate(res, _orig_val)
      res.id_hyphenate
    end

    #
    # Converts to an underscored identifier (alphanumeric with underscores, ending with underscore)
    # @param [String] res - the string value to format
    # @return [String] underscored identifier
    def id_underscore(res, _orig_val)
      res.id_underscore
    end

    #
    # Returns the first character in uppercase
    # @param [String] res - the string value to format
    # @return [String] first character in uppercase
    def initial(res, _orig_val)
      res.first&.upcase
    end

    #
    # Returns the first character as-is
    # @param [String] res - the string value to format
    # @return [String] first character
    def first(res, _orig_val)
      res.first
    end

    #
    # Calculates age in years from a date value
    # @param [Date, DateTime] orig_val - the date to calculate age from
    # @return [Integer, nil] age in years or nil if not a valid date
    def age(_res, orig_val)
      return unless orig_val.respond_to? :year

      today = ::Date.today
      age = today.year - orig_val.year
      age -= 1 if today < orig_val + age.years
      age
    end

    #
    # Formats a date according to user's date format preference (e.g., mm/dd/yyyy or dd/mm/yyyy)
    # @param [Date, DateTime] orig_val - the date to format
    # @return [String] formatted date string
    def date(_res, orig_val)
      Formatter::Date.format(orig_val, current_user: current_user)
    end

    #
    # Show the date and time as it was set (as if no timezone was specified)
    # without adjusting to the user's timezone.
    def date_time(_res, orig_val)
      Formatter::DateTime.format(orig_val, current_user: current_user)
    end

    #
    # Adjusts the date/time to the user's timezone and displays the timezone to the end.
    # Date and time only including hours:minutes and timezone of displayed time.
    def date_time_show_zone(_res, orig_val)
      Formatter::DateTime.format(orig_val, current_user: current_user,
                                           show_timezone: true,
                                           current_timezone: :user)
    end

    #
    # Forces the stored timezone to the user's timezone preference, without changing the date.
    # A stored date time intended to not have a timezone
    # will be returned as a new date time based on the user's timezone.
    def date_time_with_zone(_res, orig_val)
      Formatter::DateTime.format(orig_val, current_user: current_user,
                                           show_timezone: true,
                                           keep_date: true)
    end

    # Time only including hours:minutes in the user's timezone
    def time(_res, orig_val)
      Formatter::TimeWithZone.format(orig_val, current_user: current_user,
                                               time_only: true)
    end

    # Time only including hours:minutes
    def time_ignore_zone(_res, orig_val)
      currdate = orig_val
      Formatter::Time.format(orig_val, current_user: current_user,
                                       show_timezone: false)
    end

    # Adjusts the time to the user's timezone and displays the timezone on the end.
    # Time only including hours:minutes and timezone of displayed time
    def time_show_zone(_res, orig_val)
      currdate = orig_val
      currdate = Date.today if currdate.is_a? Time
      Formatter::Time.format(orig_val, current_user: current_user,
                                       show_timezone: true,
                                       current_timezone: :user,
                                       current_date: currdate)
    end

    # Forces the time to the user's preferred timezone
    # Time only including hours:minutes and timezone of displayed time
    def time_with_zone(_res, orig_val)
      Formatter::TimeWithZone.format(orig_val, current_user: current_user,
                                               time_only: true)
    end

    # Time for hours:minutes:seconds
    def time_sec(_res, orig_val)
      Formatter::TimeWithZone.format(orig_val, current_user: current_user,
                                               time_only: true,
                                               include_sec: true)
    end

    #
    # Formats date/time in DICOM format (YYYYMMDDHHMMSS+0000)
    # @param [Date, DateTime] orig_val - the date/time to format
    # @return [String, nil] DICOM datetime string or nil if not a valid date
    def dicom_datetime(_res, orig_val)
      orig_val.strftime('%Y%m%d%H%M%S+0000') if orig_val.respond_to? :strftime
    end

    #
    # Formats date in DICOM format (YYYYMMDD)
    # @param [Date, DateTime] orig_val - the date to format
    # @return [String, nil] DICOM date string or nil if not a valid date
    def dicom_date(_res, orig_val)
      orig_val.strftime('%Y%m%d') if orig_val.respond_to? :strftime
    end

    #
    # Formats date in REDCap format (YYYY-MM-DD)
    # @param [Date, DateTime] orig_val - the date to format
    # @return [String, nil] REDCap date string or nil if not a valid date
    def redcap_date(_res, orig_val)
      orig_val.strftime('%Y-%m-%d') if orig_val.respond_to? :strftime
    end

    #
    # Formats date/time in ISO 8601 format (YYYY-MM-DDTHH:MM:SS+00:00)
    # @param [Date, DateTime] orig_val - the date/time to format
    # @return [String] ISO 8601 datetime string
    def iso8601_datetime(_res, orig_val)
      orig_val.iso8601
    end

    #
    # Joins array elements with spaces
    # @param [Array] res - the array to join
    # @return [String, nil] space-separated string or nil if not an array
    def join_with_space(res, _orig_val)
      res.join(' ') if res.is_a? Array
    end

    #
    # Joins array elements with commas and spaces
    # @param [Array] res - the array to join
    # @return [String, nil] comma-separated string or nil if not an array
    def join_with_comma(res, _orig_val)
      res.join(', ') if res.is_a? Array
    end

    #
    # Joins array elements in CSV format with proper escaping for commas and quotes
    # @param [Array] res - the array to join
    # @return [String, nil] CSV-formatted string or nil if not an array
    def join_with_csv(res, _orig_val)
      return unless res.is_a? Array

      res = CSV.generate do |csv|
        csv << res
      end

      res.split("\n").first
    end

    #
    # Joins array elements with semicolons and spaces
    # @param [Array] res - the array to join
    # @return [String, nil] semicolon-separated string or nil if not an array
    def join_with_semicolon(res, _orig_val)
      res.join('; ') if res.is_a? Array
    end

    #
    # Joins array elements with pipe characters
    # @param [Array] res - the array to join
    # @return [String, nil] pipe-separated string or nil if not an array
    def join_with_pipe(res, _orig_val)
      res.join('|') if res.is_a? Array
    end

    #
    # Joins array elements with dots
    # @param [Array] res - the array to join
    # @return [String, nil] dot-separated string or nil if not an array
    def join_with_dot(res, _orig_val)
      res.join('.') if res.is_a? Array
    end

    #
    # Joins array elements with @ symbols (useful for email addresses)
    # @param [Array] res - the array to join
    # @return [String, nil] @-separated string or nil if not an array
    def join_with_at(res, _orig_val)
      res.join('@') if res.is_a? Array
    end

    #
    # Joins array elements with forward slashes
    # @param [Array] res - the array to join
    # @return [String, nil] slash-separated string or nil if not an array
    def join_with_slash(res, _orig_val)
      res.join('/') if res.is_a? Array
    end

    #
    # Joins array elements with newlines
    # @param [Array] res - the array to join
    # @return [String, nil] newline-separated string or nil if not an array
    def join_with_newline(res, _orig_val)
      res.join("\n") if res.is_a? Array
    end

    #
    # Joins array elements with double newlines
    # @param [Array] res - the array to join
    # @return [String, nil] double newline-separated string or nil if not an array
    def join_with_2newlines(res, _orig_val)
      res.join("\n\n") if res.is_a? Array
    end

    #
    # Removes blank/empty elements from array
    # @param [Array] res - the array to compact
    # @return [Array, nil] array without blank elements or nil if not an array
    def compact(res, _orig_val)
      res.reject(&:blank?) if res.is_a? Array
    end

    #
    # Sorts array elements in ascending order
    # @param [Array] res - the array to sort
    # @return [Array, nil] sorted array or nil if not an array
    def sort(res, _orig_val)
      res.sort if res.is_a? Array
    end

    #
    # Sorts array elements in descending order
    # @param [Array] res - the array to sort
    # @return [Array, nil] reverse-sorted array or nil if not an array
    def sort_reverse(res, _orig_val)
      res.sort.reverse if res.is_a? Array
    end

    #
    # Removes duplicate elements from array
    # @param [Array] res - the array to process
    # @return [Array, nil] array with unique elements or nil if not an array
    def uniq(res, _orig_val)
      res.uniq if res.is_a? Array
    end

    #
    # Converts array to Markdown unordered list format
    # @param [Array] res - the array to convert
    # @return [String, nil] Markdown list string or nil if not an array
    def markdown_list(res, _orig_val)
      "- #{res.join("\n- ")}" if res.is_a? Array
    end

    #
    # Converts array to HTML unordered list format
    # @param [Array] res - the array to convert
    # @return [String, nil] HTML list string or nil if not an array
    def html_list(res, _orig_val)
      "<ul><li>#{res.join("</li>\n  <li>")}</li></ul>" if res.is_a? Array
    end

    #
    # Sanitizes HTML and converts newlines to <br> tags
    # @param [String] res - the string to process
    # @return [String] sanitized HTML-safe string
    def plaintext(res, _orig_val)
      res = ActionController::Base.helpers.sanitize(res)
      res.gsub("\n", '<br>').html_safe
    end

    #
    # Removes leading and trailing whitespace
    # @param [String] res - the string to strip
    # @return [String] trimmed string
    def strip(res, _orig_val)
      res.strip
    end

    #
    # Splits string into array by spaces
    # @param [String] res - the string to split
    # @return [Array] array of space-separated values
    def split_space(res, _orig_val)
      res.split(' ')
    end

    #
    # Splits string into array by newlines
    # @param [String] res - the string to split
    # @return [Array] array of lines
    def split_lines(res, _orig_val)
      res.split("\n")
    end

    #
    # Splits string into array by commas
    # @param [String] res - the string to split
    # @return [Array] array of comma-separated values
    def split_comma(res, _orig_val)
      res.split(',')
    end

    #
    # Parses CSV string into array with proper handling of quoted values
    # @param [String] res - the CSV string to parse
    # @return [Array] array of parsed CSV values
    def split_csv(res, _orig_val)
      CSV.parse_line(res)
    end

    #
    # Splits string into array by semicolons
    # @param [String] res - the string to split
    # @return [Array] array of semicolon-separated values
    def split_semicolon(res, _orig_val)
      res.split(';')
    end

    #
    # Splits string into array by pipe characters
    # @param [String] res - the string to split
    # @return [Array] array of pipe-separated values
    def split_pipe(res, _orig_val)
      res.split('|')
    end

    #
    # Splits string into array by dots
    # @param [String] res - the string to split
    # @return [Array] array of dot-separated values
    def split_dot(res, _orig_val)
      res.split('.')
    end

    #
    # Splits string into array by @ symbols
    # @param [String] res - the string to split
    # @return [Array] array of @-separated values
    def split_at(res, _orig_val)
      res.split('@')
    end

    #
    # Splits string into array by forward slashes
    # @param [String] res - the string to split
    # @return [Array] array of slash-separated values
    def split_slash(res, _orig_val)
      res.split('/')
    end

    #
    # Converts Markdown text to HTML
    # @param [String] res - the Markdown string to convert
    # @return [String] HTML-safe converted string
    def markup(res, _orig_val)
      Kramdown::Document.new(res).to_html.html_safe
    end

    #
    # Converts object to YAML format (without document separator)
    # @param [Object] res - the object to convert
    # @return [String, nil] YAML string or nil if object doesn't respond to to_yaml
    def yaml(res, _orig_val)
      res.to_yaml.sub("---\n", '') if res.respond_to?(:to_yaml)
    end

    #
    # Converts object to pretty-formatted JSON
    # @param [Object] res - the object to convert
    # @return [String, nil] pretty JSON string or nil if object doesn't respond to to_json
    def json(res, _orig_val)
      JSON.pretty_generate(res) if res.respond_to?(:to_json)
    end

    #
    # Parses a JSON string into a Ruby Hash or Array
    # @param [String] res - the JSON string to parse
    # @return [Hash, Array, nil] parsed object or nil if invalid JSON
    def parse_json(res, _orig_val)
      JSON.parse(res)
    rescue JSON::ParserError, TypeError
      nil
    end

    #
    # Parses a YAML string into a Ruby Hash or Array
    # @param [String] res - the YAML string to parse
    # @return [Hash, Array, nil] parsed object or nil if invalid YAML
    def parse_yaml(res, _orig_val)
      YAML.safe_load(res)
    rescue Psych::Exception, TypeError
      nil
    end

    #
    # Returns the value or empty string if nil/missing
    # @param [Object] res - the value to check
    # @return [String] the value or empty string
    def ignore_missing(res, _orig_val)
      res || ''
    end

    #
    # Returns the last character of string or last element of array
    # @param [String, Array] res - the string or array to get last element from
    # @return [String, Object] last character or element
    def last(res, _orig_val)
      res.last
    end

    #
    # Pass-through formatter that returns the value unchanged
    # Used in JavaScript for compatibility, acts as a no-op
    # @param [Object] res - the value to return
    # @return [Object] unchanged value
    def no_html_tag(res, _orig_val)
      res
    end

    #
    # Return the general selection label in place of the field value, if one exists.
    # If not, return the original value
    # @return [String]
    def general_selection_label(res, orig_val)
      data = self.data
      data = data[:original_item] if !data.respond_to?(:_general_selections) && data.is_a?(Hash)
      return res unless data.respond_to?(:_general_selections)

      # Use the original value cast to a string, since this handles date fields better
      data._general_selections&.dig(tag_name, orig_val.to_s, :name) || res
    end
  end
end
