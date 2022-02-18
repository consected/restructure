# frozen_string_literal: true

module UserPreferencesHelper
  def timezone_options
    # TODO: Eventually, we would like to obtain the user's country and draw the options accordingly.
    #  priority_timezones are listed at the top of the list of options.
    time_zone_options_for_select(object_instance.timezone, PriorityTimezones)
  end

  def date_format_options
    DateFormats.keys
  end

  def date_time_format_options
    DateTimeFormats.keys
  end

  def time_format_options
    TimeFormats.keys
  end

  #
  # Set up the form options for "edit" and "show" forms
  def user_preferences_form_options
    # Set up the field options for a hash of no_downcase: true values,
    # based on the list of no_downcase_attributes in the model
    field_options = UserPreference.no_downcase_attributes.map { |f| [f, { no_downcase: true }] }.to_h

    {
      field_options: field_options,
      # Set the order the fields are displayed
      item_list: %i[timezone date_format time_format date_time_format],

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
      }
    }
  end

  # Time.current.strftime('%m/%d/%Y') == "02/18/2022"
  # Time.current.strftime('%d/%m/%Y') == "18/02/2022"
  DateFormats = {
    'mm/dd/yyyy' => '%m/%d/%Y',
    'dd/mm/yyyy' => '%d/%m/%Y'
  }.freeze

  # Time.current.strftime('%m/%d/%Y %-l:%M:%S %P') == "02/18/2022 2:02:14 pm"
  # Time.current.strftime('%m/%d/%Y %T') == "02/18/2022 14:02:49"
  # Time.current.strftime('%d/%m/%Y %-l:%M:%S %P') == "18/02/2022 2:03:19 pm"
  # Time.current.strftime('%d/%m/%Y %T') == "18/02/2022 13:43:38"
  DateTimeFormats = {
    'mm/dd/yyyy hh:mm:ss am/pm' => '%m/%d/%Y %-l:%M:%S %P',
    'mm/dd/yyyy 24h:mm:ss' => '%m/%d/%Y %T',
    'dd/mm/yyyy hh:mm:ss am/pm' => '%d/%m/%Y %-l:%M:%S %P',
    'dd/mm/yyyy 24h:mm:ss' => '%d/%m/%Y %T'
  }.freeze

  # Time.current.strftime('%-l:%M:%S %P') == "1:54:32 pm" with no leading zero or blank space.
  # Time.current.strftime('%T') == "13:49:24"
  TimeFormats = {
    'hh:mm:ss am/pm' => '%-l:%M:%S %P',
    '24h:mm:ss' => '%T'
  }.freeze

  PriorityTimezones = Settings::CountryCodesForTimezones.flat_map do |country_code|
    ActiveSupport::TimeZone.country_zones(country_code)
  end
  # Ensure the default timezone is amongst the priority timezones
  PriorityTimezones << ActiveSupport::TimeZone[Settings::DefaultUserTimezone]
  PriorityTimezones.uniq!.freeze
end
