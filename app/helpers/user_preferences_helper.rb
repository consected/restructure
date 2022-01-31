# frozen_string_literal: true

module UserPreferencesHelper
  def timezone_options
    ActiveSupport::TimeZone.us_zones.map(&:name)
  end

  #
  # Set up the form options for "edit" and "show" forms
  def user_preferences_form_options
    # Set up the field options for a hash of no_downcase: true values,
    # based on the list of no_downcase_attributes in the model
    field_options = UserPreference.no_downcase_attributes.map {|f| [f, { no_downcase: true }] }.to_h

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
      item_list: [:timezone, :date_format, :time_format, :date_time_format],
      field_options: field_options
    }
  end
end
