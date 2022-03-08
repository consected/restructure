# frozen_string_literal: true

module Formatter
  class TagFormatter
    attr_accessor :current_user

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
      time
      time_with_zone
      time_sec
      dicom_datetime
      dicom_date
      join_with_space
      join_with_comma
      join_with_semicolon
      join_with_newline
      join_with_2newlines
      compact
      sort
      uniq
      markdown_list
      html_list
      plaintext
      strip
      split_lines
      markup
      ignore_missing
      last
    ].freeze

    def self.format_with(operation, res, orig_val, current_user = nil)
      processor = new(current_user: current_user)

      processor.process(operation, res, orig_val)
    end

    def initialize(current_user: nil)
      self.current_user = current_user
    end

    def process(operation, res, orig_val)
      if operation.in?(ValidOps)
        send operation, res, orig_val
      elsif operation.to_i != 0
        res[0..operation.to_i]
      else
        res
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
      Formatter::TimeWithZone.format(orig_val, current_user: current_user, date_only: true)
    end

    def date_time(_res, orig_val)
      Formatter::DateTime.format(orig_val, current_user: current_user)
    end

    # Date and time only including hours:minutes and timezone of displayed time
    def date_time_with_zone(_res, orig_val)
      Formatter::DateTime.format(orig_val, current_user: current_user, show_timezone: true)
    end

    # Time only including hours:minutes
    def time(_res, orig_val)
      Formatter::TimeWithZone.format(orig_val, current_user: current_user, time_only: true)
    end

    # Time only including hours:minutes and timezone of displayed time
    def time_with_zone(_res, orig_val)
      Formatter::TimeWithZone.format(orig_val, current_user: current_user, time_only: true, show_timezone: true)
    end

    # Time for hours:minutes:seconds
    def time_sec(_res, orig_val)
      Formatter::TimeWithZone.format(orig_val, current_user: current_user, time_only: true, include_sec: true)
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

    def join_with_semicolon(res, _orig_val)
      res.join('; ') if res.is_a? Array
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

    def uniq(res, _orig_val)
      res.uniq if res.is_a? Array
    end

    def markdown_list(res, _orig_val)
      "  - #{res.join("\n  - ")}" if res.is_a? Array
    end

    def html_list(res, _orig_val)
      "<ul><li>#{res.join("</li>\n  <li>")}</li></ul>'" if res.is_a? Array
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

    def markup(res, _orig_val)
      Kramdown::Document.new(res).to_html.html_safe
    end

    def ignore_missing(res, _orig_val)
      res || ''
    end

    def last(res, _orig_val)
      res.last
    end
  end
end
