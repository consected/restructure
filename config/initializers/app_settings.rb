class Settings
  StartYearRange = 1900..(Date.current.year)
  EndYearRange = 1900..(Date.current.year)
  AgeRange = 1..150
  CareerYearsRange = 0..50

  PositiveIntPattern = '\\d+'.freeze
  AgePattern = '\\d{1,3}'.freeze
  YearFieldPattern = '\\d{4,4}'.freeze


  UserTimeout = (Rails.env.production? ? 30 : 60).minutes.freeze
  AdminTimeout = (Rails.env.production? ? 30 : 60).minutes.freeze

  OsWordsFile = "/usr/share/dict/words"
  PasswordEntropyConfig = {
    min_entropy: (Rails.env.test? ? 1 : 20),
    min_word_length: 4,
    extra_dictionary_words: :word_list,
    use_dictionary: !Rails.env.test?
  }.freeze

  # Force a 'from email' address for notifications
  # If not set (nil), then the current user email address will be used,
  # which may fail on some email servers if the domain name does not match
  # a verified domain name.
  NotificationsFromEmail = ENV['FPHS_FROM_EMAIL']
  # Email address for admin contact
  AdminEmail = ENV['FPHS_ADMIN_EMAIL'] || 'fphsetl@hms.harvard.edu'

  TwoFactorAuthDisabled = (ENV['FPHS_2FA_AUTH_DISABLED'] == 'true')
  TwoFactorAuthIssuer = ENV['FPHS_2FA_APP'] || 'FPHS Apps'
  TwoFactorAuthDrift = (ENV['FPHS_2FA_DRIFT'] || 30).to_i

  CheckPrevPasswords = (ENV['FPHS_CHECK_PREV_PASSWORDS'] || (Rails.env.development? ? 0 : 5)).to_i
  PasswordAgeLimit = (ENV['FPHS_PASSWORD_AGE_LIMIT'] || 90).to_i
  PasswordReminderDays = (ENV['FPHS_PASSWORD_REMINDER_DAYS'] || 5).to_i
  PasswordMaxAttempts = (ENV['FPHS_PASSWORD_MAX_ATTEMPTS'] || 3).to_i

  EnvironmentName = ENV['FPHS_ENV_NAME'] || 'unknown'
  BaseUrl = ENV['BASE_URL']

  SearchResultsLimit = ENV['FPHS_RESULT_LIMIT']

  olat = ENV['FPHS_LOAD_APP_TYPES']
  if olat.blank?
    olat = nil
  else
    olat = olat.split(',').map(&:strip).map(&:to_i)
  end
  OnlyLoadAppTypes = olat

  TemplateUserEmail = 'template@template'

end
