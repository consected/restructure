module Formatter
  module Date
    def self.format(data, _options = nil, current_user: nil, iso: nil, utc: nil)
      unless data.blank?

        df = if iso
               '%Y-%m-%d'
             elsif current_user
               current_user.user_preference.pattern_for_date_format
             else
               UserPreference.default_pattern_for_date_format
             end

        data = data.to_time.utc if utc

        res = data.strftime(df)

        return res
      end
      nil
    end

    def self.format_error_message(_data = nil)
      'Check email address is a valid format.'
    end
  end
end
