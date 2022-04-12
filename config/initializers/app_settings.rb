# frozen_string_literal: true

class Settings
  DefaultMigrationSchema = 'ml_app'
  DefaultSchemaOwner = ENV['FPHS_DEFAULT_SCHEMA_OWNER'] || 'restrdba'

  # Does not set the prefix, just specifies what we search by in jobs
  GlobalIdPrefix = 'fpa1'

  StartYearRange = (1900..(Date.current.year)).freeze
  EndYearRange = (1900..(Date.current.year)).freeze
  AgeRange = (1..150).freeze
  CareerYearsRange = (0..50).freeze

  PositiveIntPattern = '\\d+'
  AgePattern = '\\d{1,3}'
  YearFieldPattern = '\\d{4,4}'

  # Inactivity timeouts for user / admin sessions
  UserTimeout = (Rails.env.production? ? 30 : 60).minutes.freeze
  AdminTimeout = (Rails.env.production? ? 30 : 60).minutes.freeze

  OsWordsFile = '/usr/share/dict/words'
  # Setup information for the StrongPassword::StrengthChecker and
  # password setting
  PasswordEntropyConfig = {
    min_entropy: (Rails.env.test? ? 1 : 20),
    min_word_length: 4,
    extra_dictionary_words: :word_list,
    use_dictionary: !Rails.env.test?
  }.freeze

  # Default logo filename. Can be overridden on an app by app basis with the "logo filename" app configuration.
  # The logo file itself should be placed in `app/assets/images` or directly in `public/``. Alternatively, place it in
  # `public/app_specific/<app folder>`` and use the appropriate relative path `/app_specific/<app folder>` in the config.
  DefaultLogo = 'restructure-logo.svg'

  # Force a 'from email' address for notifications
  # If not set (nil), then the current user email address will be used,
  # which may fail on some email servers if the domain name does not match
  # a verified domain name.
  NotificationsFromEmail = ENV['FPHS_FROM_EMAIL']
  # Email address for admin contact
  AdminEmail = ENV['FPHS_ADMIN_EMAIL'] || 'admin@restructure'
  # Email address that identifies the batch user profile. Defaults to the user that matches the AdminEmail
  BatchUserEmail = ENV['FPHS_BATCH_USER_EMAIL'] || AdminEmail

  # Set the max number of recipients for a message, to avoid an unexpected nasty error spamming the whole organization
  MaxNotificationRecipients = ENV['FPHS_MAX_NOTIFY_RECIPS']&.to_i || 200

  # Disable 2FA by setting to true. The environment variable should be 'true' to set this
  TwoFactorAuthDisabled = (ENV['FPHS_2FA_AUTH_DISABLED'] == 'true')
  # App name that appears within 2FA authenticator app
  TwoFactorAuthIssuer = ENV['FPHS_2FA_APP'] || 'ReStructure'
  # Number of seconds to use for 2FA token drift (the older it is allowed to be and still be valid)
  TwoFactorAuthDrift = (ENV['FPHS_2FA_DRIFT'] || 30).to_i

  # Check number of previous passwords back to check for new password repeating an old one
  CheckPrevPasswords = (ENV['FPHS_CHECK_PREV_PASSWORDS'] || (Rails.env.development? ? 0 : 5)).to_i
  # Expire the password after a number of days
  PasswordAgeLimit = (ENV['FPHS_PASSWORD_AGE_LIMIT'] || 90).to_i
  # Number of days before a password expires to remind a user by email
  PasswordReminderDays = (ENV['FPHS_PASSWORD_REMINDER_DAYS'] || 15).to_i
  # Repeat the reminder every number of days until the password is updated or it expires
  PasswordReminderRepeatDays = (ENV['FPHS_PASSWORD_REMINDER_REPEAT_DAYS'] || 4).to_i
  # Maximum password attempts before account is locked
  PasswordMaxAttempts = (ENV['FPHS_PASSWORD_MAX_ATTEMPTS'] || 3).to_i

  # email = Sends an unlock link to the user email
  # time  = Re-enables login after a certain amount of time (see :unlock_in below)
  # both  = Enables both strategies
  # none  = No unlock strategy. You should handle unlocking by yourself.
  PasswordUnlockStrategy = (ENV['FPHS_PASSWORD_UNLOCK_STRATEGY'] || 'time').to_sym

  # Used to identify the environment this application server belongs to. Also available in
  # text substitution as curly substitution {{environment_name}}
  EnvironmentName = ENV['FPHS_ENV_NAME'] || 'App'
  # Allow text substitutions for messages, etc to provide a base URL for the app, accessible
  # using the curly substitution {{base_url}}
  BaseUrl = ENV['BASE_URL'] || '(not set)'
  # title tag page title, appears in tab or browser heading
  PageTitle = ENV['PAGE_TITLE'] || 'ReStructure'

  # Registration Settings
  # Since passwords have generated upon user creation, we must suppress generating a password
  # with the user (self) registration feature.
  AllowUsersToRegister = (ENV['ALLOW_USERS_TO_REGISTER'].to_s.downcase == 'true')
  # Admin assigned to newly created user through the user registration feature
  RegistrationAdminEmail = ENV['REGISTRATION_ADMIN_EMAIL'] || AdminEmail
  # Template user for creating new users. The roles from this user are copied to the new user.
  DefaultUserTemplateEmail = ENV['DEFAULT_USER_TEMPLATE_EMAIL'] || 'registration@template'

  # Admins may be able to create other admins.
  AllowAdminsToManageAdmins = (ENV['ALLOW_ADMINS_TO_MANAGE_ADMINS'].to_s.downcase == 'true')

  # URL to appear on home page for users with login issues to contact
  DefaultLoginIssuesUrl = AllowUsersToRegister ? '/users/password/new' : "mailto: #{AdminEmail}?subject=Login%20Issues"
  LoginIssuesUrl = ENV['LOGIN_ISSUES_URL'] || DefaultLoginIssuesUrl

  # Adding substitutions or conditional verbiage in the markdown files is not supported at this time. Until then,
  # show the login_issues_url when users are created by administrators.
  DidntReceiveConfirmationInstructionsUrl = AllowUsersToRegister ? '/users/confirmation/new' : LoginIssuesUrl

  # Block to appear at top of login page as a user message
  LoginMessage = ENV['LOGIN_MESSAGE']
  # Maximum limit on master search results
  SearchResultsLimit = ENV['FPHS_RESULT_LIMIT']

  #
  # Limit the app types an application server delivers.
  # A comma separated list, where all entries must be active app types in app_types table
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

  # @template is an email extension to be used to ensure user related configurations are exported
  # and a template is a good way to allow all related roles to be represented, for copying by an admin
  TemplateUserEmailPattern = '@template'
  # For the SQL LIKE operator
  TemplateUserEmailPatternForSQL = "%#{TemplateUserEmailPattern}"
  # A template user is defined to allow user roles to be set up even if no real users are assigned
  TemplateUserEmail = "template#{TemplateUserEmailPattern}"

  # A dummy role used by all user access controls to allow them to be exported, even if no other
  # roles or users are assigned
  AppTemplateRole = '_app_'

  # Initial configurations for the bulk messaging app
  def self.bulk_msg_app
    Admin::AppType.where(name: 'bulk-msg').first
  end

  def self.bulk_msg_master
    Master.find(-1)
  end

  # Master record to use for admin features that need an underlying master, such as file store
  def self.admin_master
    @admin_master ||= Master.find(-2)
  end

  # nfs_store role for admin features that provide file store containers
  def self.admin_nfs_role
    'nfs_store group 601'
  end

  # A list of resource names for admin classes that us filestore for file storage
  FilestoreAdminResourceNames = %w[redcap__project_admin].freeze

  #
  # Short links are generated and can be used by text substitutions
  # Length of a short code
  ShortcodeLength = 6
  # Website enabled public bucket for shortlink files
  DefaultShortLinkS3Bucket = ENV['FPHS_SHORTLINK_BUCKET'] || (Rails.env.production? ? 'fphs.link' : 'test-shortlink.fphs.link')
  # Log bucket for link clicks to be recorded and retrieved for analytics
  DefaultShortLinkLogS3Bucket = ENV['FPHS_SHORTLINK_LOG_BUCKET'] || (Rails.env.production? ? 'url-shortener-logs.fphs' : 'test-fphs-url-shortener-logs')
  LogBucketPrefix = 'access/'

  # Default table names (and associated configs) for the primary CRM (Zeus) app
  DefaultSubjectInfoTableName = 'player_infos'
  BestAccuracyScore = 12
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
  # Hash of options are:
  # {
  #    returnMetadataOnly: false,
  #    exportSurveyFields: true,
  #    exportDataAccessGroups: true,
  #    returnFormat: 'json'
  # }
  RedcapRecordsRequestOptions = Rails.env.test? ? nil : { exportSurveyFields: true }
  RedcapMetadataRequestOptions = nil

  # Alternative to blindly using inflector acronyms.
  # This array of acronyms will be enforced for titleize only, avoiding
  # existing expectations around class names being broken
  CaptionAcronyms = %w[IPA IPAs BHS PI PIs HMS FPHS].freeze

  # Prevent versioning of dynamic definitions
  DisableVDef = ENV.key?('FPHS_DISABLE_VDEF') ? ENV['FPHS_DISABLE_VDEF'] == 'true' : Rails.env.development?

  # Timezones
  # Use the the country alpha2 code for the country code. For example,
  # ISO3166::Country.find_country_by_iso_short_name('united states of america').alpha2 == 'US'
  # If setting more than one country, separate them with a blank-space.
  # For example, PRIORITY_TIMEZONE_COUNTRY_CODES='us gb au'
  CountryCodesForTimezones = (ENV['PRIORITY_TIMEZONE_COUNTRY_CODES']&.split || %i[us ie gb de gr au nz]).freeze

  # Use the timezone name or identifier. For example, "London" or "Eastern Time (US & Canada)".
  # To obtain the timezone identifiers, execute ActiveSupport::TimeZone.country_zones(<country alpha2 code>)
  # For example, ActiveSupport::TimeZone.country_zones('GB').map(&:name) == ["Edinburgh", "London"]
  DefaultUserTimezone = (ENV['DEFAULT_TIMEZONE'] || 'Eastern Time (US & Canada)').freeze

  # Date, Time and DateTime formats
  #
  # Set DEFAULT_DATE_FORMAT to mm/dd/yyyy or dd/mm/yyyy.
  DefaultDateFormat = (ENV['DEFAULT_DATE_FORMAT'] || 'mm/dd/yyyy').freeze

  # Set DEFAULT_DATE_TIME_FORMAT to:
  #   mm/dd/yyyy hh:mm am/pm
  #   mm/dd/yyyy 24h:mm
  #   dd/mm/yyyy hh:mm am/pm
  #   dd/mm/yyyy 24h:mm
  DefaultDateTimeFormat = (ENV['DEFAULT_DATE_TIME_FORMAT'] || 'mm/dd/yyyy hh:mm am/pm').freeze

  # Set DEFAULT_TIME_FORMAT to hh:mm am/pm or 24h:mm.
  DefaultTimeFormat = (ENV['DEFAULT_TIME_FORMAT'] || 'hh:mm am/pm').freeze
end
