# frozen_string_literal: true

module UserPreferencesHelper
  def timezone_options
    [
      'Atlantic Time (Canada)',
      'Eastern Time (US & Canada)',
      'Central Time (US & Canada)',
      'Mountain Time (US & Canada)',
      'Pacific Time (US & Canada)',
      'Alaska',
      'Hawaii',
      'Puerto Rico'
    ]
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
