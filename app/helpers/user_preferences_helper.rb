# frozen_string_literal: true

module UserPreferencesHelper

  def timezone_options
    # TODO: Eventually, we would like to obtain the user's country and draw the options accordingly.
    #  priority_timezones are listed at the top of the list of options.
    priority_timezones_for = %i[us ie gb de gr au].flat_map do |country_code|
      ActiveSupport::TimeZone.country_zones(country_code)
    end
    time_zone_options_for_select(object_instance.timezone, priority_timezones_for)
  end

  def date_format_options
    %w[mm/dd/yyyy dd/mm/yyyy]
  end

  def date_time_format_options
    ['mm/dd/yyyy hh:mm:ss am/pm', 'mm/dd/yyyy 24h:mm:ss', 'dd/mm/yyyy hh:mm:ss am/pm', 'dd/mm/yyyy 24h:mm:ss']
  end

  def time_format_options
    ['hh:mm:ss am/pm', '24h:mm:ss']
  end

  #
  # Set up the form options for "edit" and "show" forms
  def user_preferences_form_options
    # Set up the field options for a hash of no_downcase: true values,
    # based on the list of no_downcase_attributes in the model
    field_options = UserPreference.no_downcase_attributes.map { |f| [f, { no_downcase: true }] }.to_h

    {
      # caption_before: {
      #   pattern_for_date_format: {
      #     caption: 'Show date as'
      #   }
      # },

      labels: {
        timezone: 'Timezone',
        date_format: 'Show date as',
        date_time_format: 'Show date and time as',
        time_format: 'Show time as'
      },
      # Set the order the fields are displayed
      item_list: %i[timezone date_format time_format date_time_format],
      field_options: field_options
    }
  end
end
