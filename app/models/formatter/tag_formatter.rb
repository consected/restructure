# frozen_string_literal: true

module Formatter
  module TagFormatter
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
      last
    ].freeze

    def self.format_with(operation, res, orig_val)
      if operation.in?(ValidOps)
        send operation, res, orig_val
      elsif operation.to_i != 0
        res[0..operation.to_i]
      else
        res
      end
    end

    def self.capitalize(res, _orig_val)
      res.capitalize
    end

    def self.titleize(res, _orig_val)
      res.captionize
    end

    def self.uppercase(res, _orig_val)
      res.upcase
    end

    def self.lowercase(res, _orig_val)
      res.downcase
    end

    def self.underscore(res, _orig_val)
      res.underscore
    end

    def self.hyphenate(res, _orig_val)
      res.hyphenate
    end

    def self.id_hyphenate(res, _orig_val)
      res.id_hyphenate
    end

    def self.id_underscore(res, _orig_val)
      res.id_underscore
    end

    def self.initial(res, _orig_val)
      res.first&.upcase
    end

    def self.first(res, _orig_val)
      res.first
    end

    def self.age(_res, orig_val)
      return unless orig_val.respond_to? :year

      today = ::Date.today
      age = today.year - orig_val.year
      age -= 1 if today < orig_val + age.years
      age
    end

    def self.date(_res, orig_val)
      Formatter::TimeWithZone.format(orig_val, current_user: current_user, date_only: true)
    end

    def self.time(_res, orig_val)
      Formatter::TimeWithZone.format(orig_val, current_user: current_user, time_only: true)
    end

    def self.dicom_datetime(_res, orig_val)
      orig_val.strftime('%Y%m%d%H%M%S+0000') if orig_val.respond_to? :strftime
    end

    def self.dicom_date(_res, orig_val)
      orig_val.strftime('%Y%m%d') if orig_val.respond_to? :strftime
    end

    def self.join_with_space(res, _orig_val)
      res.join(' ') if res.is_a? Array
    end

    def self.join_with_comma(res, _orig_val)
      res.join(', ') if res.is_a? Array
    end

    def self.join_with_semicolon(res, _orig_val)
      res.join('; ') if res.is_a? Array
    end

    def self.join_with_newline(res, _orig_val)
      res.join("\n") if res.is_a? Array
    end

    def self.join_with_2newlines(res, _orig_val)
      res.join("\n\n") if res.is_a? Array
    end

    def self.compact(res, _orig_val)
      res.reject(&:blank?) if res.is_a? Array
    end

    def self.sort(res, _orig_val)
      res.sort if res.is_a? Array
    end

    def self.uniq(res, _orig_val)
      res.uniq if res.is_a? Array
    end

    def self.markdown_list(res, _orig_val)
      "  - #{res.join("\n  - ")}" if res.is_a? Array
    end

    def self.html_list(res, _orig_val)
      "<ul><li>#{res.join("</li>\n  <li>")}</li></ul>'" if res.is_a? Array
    end

    def self.plaintext(res, _orig_val)
      res = ActionController::Base.helpers.sanitize(res)
      res.gsub("\n", '<br>').html_safe
    end

    def self.strip(res, _orig_val)
      res.strip
    end

    def self.split_lines(res, _orig_val)
      res.split("\n")
    end

    def self.markup(res, _orig_val)
      Kramdown::Document.new(res).to_html.html_safe
    end

    def self.ignore_missing(res, _orig_val)
      res || ''
    end

    def self.last(res, _orig_val)
      res.last
    end
  end
end
