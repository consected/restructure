# frozen_string_literal: true

module Redcap
  #
  # General utilities
  class Utilities
    def self.html_to_plain_text(html)
      return '' unless html

      html = html.gsub(%r{<br\s*/?>}, "\n")
      ActionController::Base.helpers.strip_tags(html).gsub('&nbsp;', ' ')
    end

    def self.date_time_to_api_string(datetime)
      datetime.strftime('%Y-%m-%d %H:%M:%S')
    end
  end
end
