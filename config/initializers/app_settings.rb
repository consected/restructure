# frozen_string_literal: true

class Settings
  PageTitle = 'FPHS'
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
  AdminEmail = ENV['FPHS_ADMIN_EMAIL']

  # Set the max number of recipients for a message, to avoid an unexpected nasty error spamming the whole organization
  MaxNotificationRecipients = ENV['FPHS_MAX_NOTIFY_RECIPS']&.to_i || 200

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

  EnvironmentName = ENV['FPHS_ENV_NAME'] || 'App'
  BaseUrl = ENV['BASE_URL']

  LoginIssuesUrl = ENV['LOGIN_ISSUES_URL'] || "mailto: #{AdminEmail}?subject=Login%20Issues"
  LoginMessage = ENV['LOGIN_MESSAGE']

  SearchResultsLimit = ENV['FPHS_RESULT_LIMIT']

  olat = ENV['FPHS_LOAD_APP_TYPES']
  prev_olat = Rails.cache.read('Settings::FPHS_LOAD_APP_TYPES')
  # Check if the environment variable requested different app types in dev.
  # If so, clean the cache to avoid unexpected errors
  if Rails.env.development? && olat != prev_olat
    Rails.cache.clear
    Rails.cache.write('Settings::FPHS_LOAD_APP_TYPES', olat)
  end

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

  DefaultSubjectInfoTableName = 'player_infos'
  DefaultSecondaryInfoTableName = 'pro_infos'
  DefaultContactInfoTableName = 'player_contacts'
  DefaultAddressInfoTableName = 'addresses'

  # Scripted job scripts are only run from a predefined directory
  ScriptedJobDirectory = Rails.root.join('scripted_job_scripts')

  # Encryption key and salt for attribute encryption
  # @see Utilities::Encryption
  EncryptionSecretKeyBase = ENV['FPHS_ENC_SECRET_KEY_BASE'] || (Rails.env.production? ? nil : 'test')
  EncryptionSalt = ENV['FPHS_ENC_SALT'] || (Rails.env.production? ? nil : 'test-salt')

  # Dynamic models create their own migrations during configuration, if this is set
  AllowDynamicMigrations = ENV['FPHS_ALLOW_DYN_MIGRATIONS'] == 'true' || Rails.env.development?

  # Redcap records request options - additional request parameters to add / override the payload
  # to a records request.
  RedcapRecordsRequestOptions = Rails.env.production? ? { exportSurveyFields: true } : nil
end
