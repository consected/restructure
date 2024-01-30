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
      general_selection_label
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

    def capitalize(res, _orig_val)
      res.capitalize
    end

    def titleize(res, _orig_val)
      res.captionize
    end

    def uppercase(res, _orig_val)
      res.upcase
    end

    def lowercase(res, _orig_val)
      res.downcase
    end

    def underscore(res, _orig_val)
      res.underscore
    end

    def hyphenate(res, _orig_val)
      res.hyphenate
    end

    def id_hyphenate(res, _orig_val)
      res.id_hyphenate
    end

    def id_underscore(res, _orig_val)
      res.id_underscore
    end

    def initial(res, _orig_val)
      res.first&.upcase
    end

    def first(res, _orig_val)
      res.first
    end

    def age(_res, orig_val)
      return unless orig_val.respond_to? :year

      today = ::Date.today
      age = today.year - orig_val.year
      age -= 1 if today < orig_val + age.years
      age
    end

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

    # Time only including hours:minutes
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

    def dicom_datetime(_res, orig_val)
      orig_val.strftime('%Y%m%d%H%M%S+0000') if orig_val.respond_to? :strftime
    end

    def dicom_date(_res, orig_val)
      orig_val.strftime('%Y%m%d') if orig_val.respond_to? :strftime
    end

    def join_with_space(res, _orig_val)
      res.join(' ') if res.is_a? Array
    end

    def join_with_comma(res, _orig_val)
      res.join(', ') if res.is_a? Array
    end

    def join_with_csv(res, _orig_val)
      return unless res.is_a? Array

      res = CSV.generate do |csv|
        csv << res
      end

      res.split("\n").first
    end

    def join_with_semicolon(res, _orig_val)
      res.join('; ') if res.is_a? Array
    end

    def join_with_pipe(res, _orig_val)
      res.join('|') if res.is_a? Array
    end

    def join_with_dot(res, _orig_val)
      res.join('.') if res.is_a? Array
    end

    def join_with_at(res, _orig_val)
      res.join('@') if res.is_a? Array
    end

    def join_with_slash(res, _orig_val)
      res.join('/') if res.is_a? Array
    end

    def join_with_newline(res, _orig_val)
      res.join("\n") if res.is_a? Array
    end

    def join_with_2newlines(res, _orig_val)
      res.join("\n\n") if res.is_a? Array
    end

    def compact(res, _orig_val)
      res.reject(&:blank?) if res.is_a? Array
    end

    def sort(res, _orig_val)
      res.sort if res.is_a? Array
    end

    def sort_reverse(res, _orig_val)
      res.sort.reverse if res.is_a? Array
    end

    def uniq(res, _orig_val)
      res.uniq if res.is_a? Array
    end

    def markdown_list(res, _orig_val)
      "- #{res.join("\n- ")}" if res.is_a? Array
    end

    def html_list(res, _orig_val)
      "<ul><li>#{res.join("</li>\n  <li>")}</li></ul>" if res.is_a? Array
    end

    def plaintext(res, _orig_val)
      res = ActionController::Base.helpers.sanitize(res)
      res.gsub("\n", '<br>').html_safe
    end

    def strip(res, _orig_val)
      res.strip
    end

    def split_lines(res, _orig_val)
      res.split("\n")
    end

    def split_comma(res, _orig_val)
      res.split(',')
    end

    def split_csv(res, _orig_val)
      CSV.parse_line(res)
    end

    def split_semicolon(res, _orig_val)
      res.split(';')
    end

    def split_pipe(res, _orig_val)
      res.split('|')
    end

    def split_dot(res, _orig_val)
      res.split('.')
    end

    def split_at(res, _orig_val)
      res.split('@')
    end

    def split_slash(res, _orig_val)
      res.split('/')
    end

    def markup(res, _orig_val)
      Kramdown::Document.new(res).to_html.html_safe
    end

    def yaml(res, _orig_val)
      res.to_yaml.sub("---\n", '') if res.respond_to?(:to_yaml)
    end

    def json(res, _orig_val)
      JSON.pretty_generate(res) if res.respond_to?(:to_json)
    end

    def ignore_missing(res, _orig_val)
      res || ''
    end

    def last(res, _orig_val)
      res.last
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
