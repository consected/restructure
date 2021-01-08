# frozen_string_literal: true

module Formatter
  module TagFormatter
    ValidOps = %w[
      format_with
      capitalize
      titleize
      uppercase
      lowercase
      underscore
      hyphenate
      initial
      first
      age
      date
      time
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
      int_index
    ].freeze

    def format_with(operation, res, orig_val)
      if operation.in?(ValidOps)
        send operation, res, orig_val
      elsif operation.to_i != 0
        int_index res, orig_val
      end
    end

    def capitalize(res, _orig_val)
      res.capitalize
    end

    def titleize(res, _orig_val)
      res.titleize
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

    def time(_res, orig_val)
      Formatter::TimeWithZone.format(orig_val, current_user: current_user, time_only: true)
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

    def plaintext(res, orig_val)
      res = ActionController::Base.helpers.sanitize(res, orig_val)
      res.gsub("\n", '<br>').html_safe
    end

    def strip(res, _orig_val)
      res.strip
    end

    def split_lines(res, _orig_val)
      res.split("\n")
    end

    def markup(res, orig_val)
      Kramdown::Document.new(res, orig_val).to_html.html_safe
    end

    def ignore_missing(res, _orig_val)
      res || ''
    end

    def int_index(res, _orig_val)
      res[0..op.to_i]
    end
  end
end
