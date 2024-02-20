# frozen_string_literal: true

date_formats = {
  concise: '%Y-%m-%d'
}

Time::DATE_FORMATS.merge! date_formats
Date::DATE_FORMATS.merge! date_formats
