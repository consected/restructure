# frozen_string_literal: true

class Settings
  DefaultMigrationSchema = 'ml_app'
  DefaultSchemaOwner = 'fphs'

  StartYearRange = (1900..(Date.current.year)).freeze
  EndYearRange = (1900..(Date.current.year)).freeze
  AgeRange = (1..150).freeze
  CareerYearsRange = (0..50).freeze

  PositiveIntPattern = '\\d+'
  AgePattern = '\\d{1,3}'
  YearFieldPattern = '\\d{4,4}'

  UserTimeout = (Rails.env.production? ? 30 : 60).minutes.freeze
  AdminTimeout = (Rails.env.production? ? 30 : 60).minutes.freeze

  OsWordsFile = '/usr/share/dict/words'
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

  # email = Sends an unlock link to the user email
  # time  = Re-enables login after a certain amount of time (see :unlock_in below)
  # both  = Enables both strategies
  # none  = No unlock strategy. You should handle unlocking by yourself.
  PasswordUnlockStrategy = (ENV['FPHS_PASSWORD_UNLOCK_STRATEGY'] || 'time').to_sym

  EnvironmentName = ENV['FPHS_ENV_NAME'] || 'unknown'
  BaseUrl = ENV['BASE_URL']

  LoginIssuesUrl = ENV['LOGIN_ISSUES_URL'] || "mailto: #{AdminEmail}?subject=Login%20Issues"
  LoginMessage = ENV['LOGIN_MESSAGE']

  SearchResultsLimit = ENV['FPHS_RESULT_LIMIT']

  olat = ENV['FPHS_LOAD_APP_TYPES']
  olat = if olat.blank?
           nil
         else
           olat.split(',').map(&:strip).map(&:to_i)
         end
  OnlyLoadAppTypes = olat

  TemplateUserEmail = 'template@template'
  TemplateUserEmailPattern = '%@template'
  AppTemplateRole = '_app_'

  def self.bulk_msg_app
    Admin::AppType.where(name: 'bulk-msg').first
  end

  def self.bulk_msg_master
    Master.find(-1)
  end

  ShortcodeLength = 6
  DefaultShortLinkS3Bucket = ENV['FPHS_SHORTLINK_BUCKET'] || (Rails.env.production? ? 'fphs.link' : 'test-shortlink.fphs.link')
  DefaultShortLinkLogS3Bucket = ENV['FPHS_SHORTLINK_LOG_BUCKET'] || (Rails.env.production? ? 'url-shortener-logs.fphs' : 'test-fphs-url-shortener-logs')
  LogBucketPrefix = 'access/'
end
