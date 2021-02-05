# frozen_string_literal: true

module Redcap
  #
  # General utilities
  class Utilities
    def self.html_to_plain_text(html)
      html = html.gsub(%r{<br\s*/?>}, '\n')
      ActionController::Base.helpers.strip_tags(html).gsub('&nbsp;', ' ')
    end
  end
end
