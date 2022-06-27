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

      caption_before: {
        all_fields: {
          show_caption: template_block('ui user preferences caption'),
          edit_caption: template_block('ui user preferences caption')
        }
      },
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

  # Time.current.strftime('%m/%d/%Y %-l:%M %P') == "02/18/2022 2:02 pm"
  # Time.current.strftime('%m/%d/%Y %H:%M') == "02/18/2022 14:02"
  # Time.current.strftime('%d/%m/%Y %-l:%M %P') == "18/02/2022 2:03 pm"
  # Time.current.strftime('%d/%m/%Y %H:%M') == "18/02/2022 13:43"
  # Time.current.strftime('%m/%d/%Y %-l:%M:%S %P') == "02/18/2022 2:02:20 pm"
  # Time.current.strftime('%m/%d/%Y %T') == "02/18/2022 14:02:30"
  # Time.current.strftime('%d/%m/%Y %-l:%M:%S %P') == "18/02/2022 2:03:01 pm"
  # Time.current.strftime('%d/%m/%Y %T') == "18/02/2022 13:43:33"
  DateTimeFormats = {
    'mm/dd/yyyy hh:mm am/pm' => {
      hours_minutes: '%m/%d/%Y %-l:%M %P',
      with_secs: '%m/%d/%Y %-l:%M:%S %P'
    },
    'mm/dd/yyyy 24h:mm' => {
      hours_minutes: '%m/%d/%Y %H:%M',
      with_secs: '%m/%d/%Y %T'
    },
    'dd/mm/yyyy hh:mm am/pm' => {
      hours_minutes: '%d/%m/%Y %-l:%M %P',
      with_secs: '%d/%m/%Y %-l:%M:%S %P'
    },
    'dd/mm/yyyy 24h:mm' => {
      hours_minutes: '%d/%m/%Y %H:%M',
      with_secs: '%d/%m/%Y %T'
    }
  }.freeze

  # Time.current.strftime('%-l:%M %P') == "1:54:32 pm" with no leading zero or blank space.
  # Time.current.strftime('%H:%M') == "13:49"
  # Time.current.strftime('%-l:%M:%S %P') == "1:54:32 pm" with no leading zero or blank space.
  # Time.current.strftime('%T') == "13:49"
  TimeFormats = {
    'hh:mm am/pm' => {
      hours_minutes: '%-l:%M %P',
      with_secs: '%-l:%M:%S %P'
    },
    '24h:mm' => {
      hours_minutes: '%H:%M',
      with_secs: '%T'
    }
  }.freeze

  PriorityTimezones = Settings::CountryCodesForTimezones.flat_map do |country_code|
    ActiveSupport::TimeZone.country_zones(country_code)
  end
  # Ensure the default timezone is amongst the priority timezones
  PriorityTimezones << ActiveSupport::TimeZone[Settings::DefaultUserTimezone]
  PriorityTimezones.uniq!.freeze
end
