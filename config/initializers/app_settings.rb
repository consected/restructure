# frozen_string_literal: true

class Settings
  LogLevel = DefaultSettings::LogLevel
  DefaultMigrationSchema = DefaultSettings::DefaultMigrationSchema
  DefaultSchemaOwner = ENV['FPHS_DEFAULT_SCHEMA_OWNER'].presence || DefaultSettings::DefaultSchemaOwner
  MigrationTimeoutSec = 120
  MaxPostgresIdentifierLength = 63

  # Does not set the prefix, just specifies what we search by in jobs
  GlobalIdPrefix = DefaultSettings::GlobalIdPrefix

  StartYearRange = (1900..(Date.current.year))
  EndYearRange = (1900..(Date.current.year))
  AgeRange = (1..150)
  CareerYearsRange = (0..50)

  PositiveIntPattern = '\\d+'
  AgePattern = '\\d{1,3}'
  YearFieldPattern = '\\d{4,4}'

  # Inactivity timeouts for user / admin sessions
  UserTimeout = (ENV['USER_TIMEOUT_MINS'].presence || 30).to_i.minutes.freeze
  AdminTimeout = (ENV['ADMIN_TIMEOUT_MINS'].presence || 30).to_i.minutes.freeze

  # Max seconds a request will retry acquiring HandlebarsPrecompiler::FileLock before
  # proceeding unlocked (issue #1362). Short by design: the lock is a work-duplication
  # optimisation, never a correctness mechanism, so a user request must not wait long.
  HandlebarsLockWaitSeconds = (ENV['FPHS_HANDLEBARS_LOCK_WAIT'].presence || 2).to_f

  # How many previous compiled-Handlebars generations to retain on disk alongside the
  # current one (issue #1362), so a process/request that has not yet observed a
  # rotation can still find its generation's compiled files. Older generations are
  # swept opportunistically.
  HandlebarsKeepGenerations = (ENV['FPHS_HANDLEBARS_KEEP_GENERATIONS'].presence || 2).to_i

  # A generation directory younger than this is never swept, regardless of
  # HandlebarsKeepGenerations, so one created moments ago can't be deleted out from
  # under a concurrent writer (issue #1362).
  HandlebarsGenerationSafetyWindowSeconds = (ENV['FPHS_HANDLEBARS_GENERATION_SAFETY_WINDOW'].presence || 60).to_i

  # HandlebarsPrecompiler::FileLock files older than this are swept opportunistically
  # (issue #1362 S7 fix) - lock file names are per user/app_type/template-set, so without
  # this they would accumulate without bound on a long-lived server. Generous relative to
  # HandlebarsLockWaitSeconds, since a lock file's mtime is its CREATION time (re-opening
  # an existing file for flock does not bump it), not its last-used time.
  HandlebarsLockFileMaxAgeSeconds = (ENV['FPHS_HANDLEBARS_LOCK_FILE_MAX_AGE'].presence || 300).to_i

  # Whether the server spawns a `prewarm:templates` pass on boot (issue #1362 Stage 2).
  # Opt-in, and always disabled in test, since specs exercise prewarming directly.
  PrewarmTemplatesEnabled = ENV['FPHS_PREWARM_TEMPLATES'] == 'true' && !Rails.env.test?

  # Only users who have signed in within this many days are candidates for prewarming.
  PrewarmSignInWindowDays = (ENV['FPHS_PREWARM_SIGN_IN_WINDOW_DAYS'].presence || 30).to_i

  # Upper bound on the number of distinct (app_type, access variant) combinations warmed
  # in one pass, to cap worst-case pass duration on an app with many disjoint variants.
  PrewarmMaxVariants = (ENV['FPHS_PREWARM_MAX_VARIANTS'].presence || 50).to_i

  # Pause between warmed renders, to keep the pass low priority relative to user requests.
  PrewarmThrottleSeconds = (ENV['FPHS_PREWARM_THROTTLE'].presence || 0.5).to_f

  OsWordsFile = '/usr/share/dict/words'
  # Setup information for the StrongPassword::StrengthChecker and
  # password setting.
  # Set PW_MIN_ENTROPY=0 to disable entropy test
  # Set PW_REGEX to blank to remove regex requirement
  # Set PW_REGEX_REQ to provide message about the password requirements, such as:
  #  "Minimum 1 upper case letter, 1 lower case letter, 1 number"
  PasswordConfig = {
    min_entropy: (Rails.env.test? ? 1 : (ENV['PW_MIN_ENTROPY'] || 20).to_i),
    min_word_length: 4,
    extra_dictionary_words: :word_list,
    use_dictionary: !Rails.env.test?,
    min_length: (ENV['PW_MIN_LEN'] || 10).to_i,
    regex: ENV.fetch('PW_REGEX', nil),
    regex_requirements: ENV.fetch('PW_REGEX_REQ', nil)
  }.freeze

  PasswordUnlockTimeMins = (ENV['PW_UNLOCK_TIME_MINS'].presence || 60).to_i.freeze

  # Default logo filename. Can be overridden on an app by app basis with the "logo filename" app configuration.
  # The logo file itself should be placed in `app/assets/images` or directly in `public/``. Alternatively, place it in
  # `public/app_specific/<app folder>`` and use the appropriate relative path `/app_specific/<app folder>` in the config.
  DefaultLogo = DefaultSettings::DefaultLogo

  # Force a 'from email' address for notifications
  # If not set (nil), then the current user email address will be used,
  # which may fail on some email servers if the domain name does not match
  # a verified domain name.
  # This must be set if user self registration is enabled.
  NotificationsFromEmail = ENV['FPHS_FROM_EMAIL'].presence || ENV['FROM_EMAIL'].presence || DefaultSettings::NotificationsFromEmail.presence
  # Email address for admin contact
  AdminEmail = ENV['FPHS_ADMIN_EMAIL'].presence || DefaultSettings::AdminEmail.presence
  # Email address that identifies the batch user profile. Defaults to the user that matches the AdminEmail
  BatchUserEmail = ENV['FPHS_BATCH_USER_EMAIL'].presence || AdminEmail.presence
  # Email address that identifies the Redcap job user profile. Defaults to the BatchUserEmail
  RedcapJobUserEmail = ENV['FPHS_RC_JOB_USER_EMAIL'].presence || BatchUserEmail.presence
  # Email address of the API-only user recommended for submitting REDCap Data Entry Trigger
  # requests. Shown as the default in the generated Data Entry Trigger endpoint URL/instructions;
  # this user still needs its own real API token, substituted manually by an admin.
  RedcapDetUserEmail = ENV['FPHS_RC_DET_USER_EMAIL'].presence || 'redcap_det@system-user'
  # Provide an email address for a technical admin to receive failure notifications
  FailureNotificationsToEmail = ENV['FAIL_TO_EMAIL'].presence || ENV['FAIL_FROM_EMAIL'].presence || DefaultSettings::FailureNotificationsToEmail.presence || Settings::AdminEmail.presence

  # Set the max number of recipients for a message, to avoid an unexpected nasty error spamming the whole organization
  MaxNotificationRecipients = ENV['FPHS_MAX_NOTIFY_RECIPS']&.to_i || 200

  # Disable 2FA by setting to true (for users and admins), user (for users only) or admin (for admins only).
  TwoFactorAuthDisabledForUser = ENV['FPHS_2FA_AUTH_DISABLED'].in?(['true', 'user'])
  TwoFactorAuthDisabledForAdmin = ENV['FPHS_2FA_AUTH_DISABLED'].in?(['true', 'admin'])

  # App name that appears within 2FA authenticator app
  TwoFactorAuthIssuer = ENV['FPHS_2FA_APP'].presence || DefaultSettings::TwoFactorAuthIssuer
  # Number of seconds to use for 2FA token drift (the older it is allowed to be and still be valid)
  TwoFactorAuthDrift = (ENV['FPHS_2FA_DRIFT'].presence || 30).to_i
  # Number of seconds the OTP entry page waits before resetting to step 1 (client-side idle timeout)
  TwoFactorAuthIdleTimeout = (ENV['FPHS_2FA_IDLE_TIMEOUT'].presence || DefaultSettings::TwoFactorAuthIdleTimeout).to_i

  # Check number of previous passwords back to check for new password repeating an old one
  CheckPrevPasswords = (ENV['FPHS_CHECK_PREV_PASSWORDS'].presence || (Rails.env.development? ? 0 : 5)).to_i
  # Expire the password after a number of days
  PasswordAgeLimit = (ENV['FPHS_PASSWORD_AGE_LIMIT'].presence || 90).to_i
  # Number of days before a password expires to remind a user by email
  PasswordReminderDays = (ENV['FPHS_PASSWORD_REMINDER_DAYS'].presence || 15).to_i
  # Repeat the reminder every number of days until the password is updated or it expires
  PasswordReminderRepeatDays = (ENV['FPHS_PASSWORD_REMINDER_REPEAT_DAYS'].presence || 4).to_i
  # Maximum password attempts before account is locked
  PasswordMaxAttempts = (ENV['FPHS_PASSWORD_MAX_ATTEMPTS'].presence || 3).to_i

  # email = Sends an unlock link to the user email
  # time  = Re-enables login after a certain amount of time (see :unlock_in below)
  # both  = Enables both strategies
  # none  = No unlock strategy. You should handle unlocking by yourself.
  PasswordUnlockStrategy = (ENV['FPHS_PASSWORD_UNLOCK_STRATEGY'].presence || 'time').to_sym

  # Used to identify the environment this application server belongs to. Also available in
  # text substitution as curly substitution {{environment_name}}
  EnvironmentName = ENV['FPHS_ENV_NAME'].presence || 'App'
  # Allow text substitutions for messages, etc to provide a base URL for the app, accessible
  # using the curly substitution {{base_url}}
  BaseUrl = ENV['BASE_URL'].presence || DefaultSettings::BaseUrl
  # title tag page title, appears in tab or browser heading
  PageTitle = ENV['PAGE_TITLE'].presence || DefaultSettings::PageTitle

  # Registration Settings
  # Since passwords have generated upon user creation, we must suppress generating a password
  # with the user (self) registration feature.
  # For system tests, set AllowUsersToRegister to true. Change it to false during testing where necessary.
  AllowUsersToRegister = Rails.env.test? || (ENV['ALLOW_USERS_TO_REGISTER'].to_s.downcase == 'true')
  # Admin assigned to newly created user through the user registration feature
  RegistrationAdminEmail = ENV['REGISTRATION_ADMIN_EMAIL'].presence || AdminEmail.presence
  # Template user for creating new users. The roles from this user are copied to the new user.
  DefaultUserTemplateEmail = ENV['DEFAULT_USER_TEMPLATE_EMAIL'].presence || 'registration@template'
  # Require an invitation code to be used to register
  InvitationCode = ENV['INVITATION_CODE'].presence
  # Add a reCAPTCHA v3 to the registration form - if not added, no reCAPTCHA will be used
  ReCaptchaSiteKey = ENV['RECAPTCHA_SITE_KEY'].presence
  ReCaptchaSecret = ENV['RECAPTCHA_SECRET'].presence
  ReCaptchaMinScore = ENV['RECAPTCHA_MIN_SCORE'].presence&.to_f
  # Admins may be able to create other admins.
  AllowAdminsToManageAdmins = (ENV['ALLOW_ADMINS_TO_MANAGE_ADMINS'].to_s.downcase == 'true')

  # Notify the NotifyEmailOnRegistration when a new admin or user is registered (notify on 'admin', 'user' or 'admin,user')
  NotifyOnRegistration = ENV['NOTIFY_ON_REGISTRATION'].presence
  NotifyEmailOnRegistration = ENV['NOTIFY_EMAIL_ON_REGISTRATION'].presence || RegistrationAdminEmail.presence

  # URL to appear on home page for users with login issues to contact
  DefaultLoginIssuesUrl = AllowUsersToRegister ? '/users/password/new' : "mailto: #{AdminEmail}?subject=Login%20Issues"
  LoginIssuesUrl = ENV['LOGIN_ISSUES_URL'] || DefaultLoginIssuesUrl

  # Adding substitutions or conditional verbiage in the markdown files is not supported at this time. Until then,
  # show the login_issues_url when users are created by administrators.
  DidntReceiveConfirmationInstructionsUrl = AllowUsersToRegister ? '/users/confirmation/new' : LoginIssuesUrl

  # Block to appear at top of login page as a user message
  LoginMessage = ENV.fetch('LOGIN_MESSAGE', nil)
  # Maximum limit on master search results
  SearchResultsLimit = ENV['FPHS_RESULT_LIMIT'].presence

  #
  # Limit the app types an application server delivers.
  # A comma separated list, where all entries must be active app types in app_types table
  olat = ENV.fetch('FPHS_LOAD_APP_TYPES', nil)
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
    Admin::AppType.active_app_types.find_by(name: 'bulk-msg')
  end

  def self.bulk_msg_master
    Master.find(-1)
  end

  # Master record to use for admin features that need an underlying master, such as file store
  def self.admin_master
    @admin_master = nil if Rails.env.development?
    @admin_master ||= Master.find(-2)
  end

  # nfs_store role for admin features that provide file store containers
  def self.admin_nfs_role
    'nfs_store group 601'
  end

  def self.nfs_store_default_app_type_id
    (ENV['NFS_STORE_DEFAULT_APP_TYPE_ID'].presence || OnlyLoadAppTypes&.first || Admin::AppType.active.first&.id || 1).to_i
  end

  # Allow-list mapping of resource names => fully qualified class name strings for
  # admin classes that use filestore for file storage. This is the single source of
  # truth used both to validate incoming `activity_log_type` parameters and to safely
  # resolve them to a model class without calling String#constantize on user input.
  FilestoreAdminResourceClasses = {
    'redcap__project_admin' => 'Redcap::ProjectAdmin'
  }.freeze

  # A list of resource names for admin classes that use filestore for file storage.
  # Derived from FilestoreAdminResourceClasses so the two stay in sync.
  FilestoreAdminResourceNames = FilestoreAdminResourceClasses.keys.freeze

  # Safely resolve a filestore admin resource name to its model class via the
  # allow-list above. Returns nil for any name that is not allow-listed.
  # @param resource_name [String]
  # @return [Class, nil]
  def self.filestore_admin_class_for(resource_name)
    class_name = FilestoreAdminResourceClasses[resource_name]
    class_name&.safe_constantize
  end

  # App type used for admin filestore containers (e.g. REDCap project files)
  FilestoreAdminAppType = 'ref-data'

  #
  # Short links are generated and can be used by text substitutions
  # Length of a short code
  ShortcodeLength = 6
  # Website enabled public bucket for shortlink files
  DefaultShortLinkS3Bucket = ENV['FPHS_SHORTLINK_BUCKET'].presence || DefaultSettings::DefaultShortLinkS3Bucket
  # Log bucket for link clicks to be recorded and retrieved for analytics
  DefaultShortLinkLogS3Bucket = ENV['FPHS_SHORTLINK_LOG_BUCKET'].presence || DefaultSettings::DefaultShortLinkLogS3Bucket
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
  EncryptionSecretKeyBase = ENV['FPHS_ENC_SECRET_KEY_BASE'].presence || (Rails.env.production? ? nil : 'test')
  EncryptionSalt = ENV['FPHS_ENC_SALT'].presence || (Rails.env.production? ? nil : 'test-salt')

  # From ENV['SECRET_KEY_BASE'] in production, or the default config/credentials.yml file
  SecretKeyBase = Rails.application.config.secret_key_base

  # Dynamic models create their own migrations during configuration, if this is set
  AllowDynamicMigrations = ENV['FPHS_ALLOW_DYN_MIGRATIONS'] == 'true' || Rails.env.development?

  # Convert inline data URI images in email bodies to MIME inline attachments
  ProcessInlineDataUriImages = ENV.key?('FPHS_PROCESS_INLINE_DATA_URI_IMAGES') ? ENV['FPHS_PROCESS_INLINE_DATA_URI_IMAGES'] == 'true' : true

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
  RedcapDataOptions = {
    run_jobs_as_user: RedcapJobUserEmail,
    run_jobs_in_app_type: 'ref-data'
  }.freeze

  # Alternative to blindly using inflector acronyms.
  # This array of acronyms will be enforced for titleize only, avoiding
  # existing expectations around class names being broken
  CaptionAcronyms = DefaultSettings::CaptionAcronyms

  # SSRF guard for admin-configurable outbound HTTP requests (Utilities::UrlSafety).
  # AllowedExternalUrlSchemes and BlockedExternalIpRanges back the default
  # validation rules; per-trigger settings tune the allowlist.
  # SSRF guard defaults applied to admin-configurable outbound URLs
  # (see Utilities::UrlSafety).
  AllowedExternalUrlSchemes = %w[http https].freeze
  BlockedExternalIpRanges = [
    IPAddr.new('0.0.0.0/8'),         # "this network"
    IPAddr.new('10.0.0.0/8'),        # RFC1918
    IPAddr.new('100.64.0.0/10'),     # CGNAT
    IPAddr.new('127.0.0.0/8'),       # loopback
    IPAddr.new('169.254.0.0/16'),    # link-local (incl. cloud metadata 169.254.169.254)
    IPAddr.new('172.16.0.0/12'),     # RFC1918
    IPAddr.new('192.0.0.0/24'),      # IETF protocol assignments
    IPAddr.new('192.168.0.0/16'),    # RFC1918
    IPAddr.new('198.18.0.0/15'),     # benchmarking
    IPAddr.new('::1/128'),           # IPv6 loopback
    IPAddr.new('fc00::/7'),          # IPv6 unique-local
    IPAddr.new('fe80::/10'),         # IPv6 link-local
    IPAddr.new('::ffff:0:0/96')      # IPv4-mapped IPv6 (further checked after unmapping)
  ].freeze

  # Optional host allowlist for the pull_external_data save trigger. When set,
  # listed hosts (exact, case-insensitive match) bypass the private-range block.
  # Configure via FPHS_PULL_EXTERNAL_DATA_ALLOWED_HOSTS as a space-separated list.
  PullExternalDataAllowedHosts = ENV['FPHS_PULL_EXTERNAL_DATA_ALLOWED_HOSTS'].to_s.split(/\s+/).reject(&:empty?).freeze
  # Global override permitting pull_external_data to reach private/loopback
  # addresses. Defaults true only in development for convenience.
  PullExternalDataAllowPrivateHosts =
    if ENV.key?('FPHS_PULL_EXTERNAL_DATA_ALLOW_PRIVATE_HOSTS')
      ENV['FPHS_PULL_EXTERNAL_DATA_ALLOW_PRIVATE_HOSTS'] == 'true'
    else
      Rails.env.development?
    end

  # Prevent versioning of dynamic definitions
  DisableVDef = ENV.key?('FPHS_DISABLE_VDEF') ? ENV['FPHS_DISABLE_VDEF'] == 'true' : Rails.env.development?

  # Timezones
  # Use the the country alpha2 code for the country code. For example,
  # ISO3166::Country.find_country_by_iso_short_name('united states of america').alpha2 == 'US'
  # If setting more than one country, separate them with a blank-space.
  # For example, PRIORITY_TIMEZONE_COUNTRY_CODES='us gb au'
  DefaultCountryCodesForTimezones = %w[us ie gb de gr au nz]
  CountryCodesForTimezones = (ENV['PRIORITY_TIMEZONE_COUNTRY_CODES'].presence&.split || DefaultCountryCodesForTimezones).freeze

  # Use the timezone name or identifier. For example, "London" or "Eastern Time (US & Canada)".
  # To obtain the timezone identifiers, execute ActiveSupport::TimeZone.country_zones(<country alpha2 code>)
  # For example, ActiveSupport::TimeZone.country_zones('GB').map(&:name) == ["Edinburgh", "London"]
  DefaultUserTimezone = (ENV['DEFAULT_TIMEZONE'].presence || 'Eastern Time (US & Canada)').freeze

  # Date, Time and DateTime formats
  #
  # Set DEFAULT_DATE_FORMAT to mm/dd/yyyy or dd/mm/yyyy.
  DefaultDateFormat = (ENV['DEFAULT_DATE_FORMAT'].presence || 'mm/dd/yyyy').freeze

  # Set DEFAULT_DATE_TIME_FORMAT to:
  #   mm/dd/yyyy hh:mm am/pm
  #   mm/dd/yyyy 24h:mm
  #   dd/mm/yyyy hh:mm am/pm
  #   dd/mm/yyyy 24h:mm
  DefaultDateTimeFormat = (ENV['DEFAULT_DATE_TIME_FORMAT'].presence || 'mm/dd/yyyy hh:mm am/pm').freeze

  # Set DEFAULT_TIME_FORMAT to hh:mm am/pm or 24h:mm.
  DefaultTimeFormat = (ENV['DEFAULT_TIME_FORMAT'].presence || 'hh:mm am/pm').freeze

  # Set the priority listing for the country select
  DefaultCountrySelect = (ENV['DEFAULT_COUNTRY_SELECT'].presence&.split || %w[US CA DE]).freeze

  # Countries for which GDPR specific terms of use should be shown
  GdprCountryCodes = %w[AT BE BG HR CY CZ DK EE FI FR DE GR HU IE IT LV LT LU MT NL PL PT RO SE SK SI ES SE GB].freeze

  AdminReportItemTypes = {
    'z-admin' => 'Admin Reports',
    'admin-user-access-overview' => 'User Access Overview'
  }

  # IMPORTANT: add any app setting config variable to the following array
  # that is worthy of showing to the admin users,
  # so it can be displayed in the server info admin view.
  AppSettingsVars = %w[
    PageTitle EnvironmentName BaseUrl
    OnlyLoadAppTypes
    DefaultMigrationSchema DefaultSchemaOwner StartYearRange EndYearRange AgeRange CareerYearsRange
    UserTimeout AdminTimeout OsWordsFile PasswordConfig
    NotificationsFromEmail AdminEmail BatchUserEmail FailureNotificationsToEmail RedcapJobUserEmail RedcapDetUserEmail
    TwoFactorAuthDisabledForUser TwoFactorAuthDisabledForAdmin TwoFactorAuthIssuer TwoFactorAuthDrift TwoFactorAuthIdleTimeout
    CheckPrevPasswords PasswordAgeLimit PasswordReminderDays PasswordMaxAttempts PasswordUnlockStrategy
    LoginIssuesUrl LoginMessage
    SearchResultsLimit
    DefaultShortLinkS3Bucket DefaultShortLinkLogS3Bucket LogBucketPrefix ShortcodeLength
    DefaultSubjectInfoTableName DefaultSecondaryInfoTableName DefaultContactInfoTableName DefaultAddressInfoTableName
    ScriptedJobDirectory
    DisableVDef AllowDynamicMigrations ProcessInlineDataUriImages
    AllowUsersToRegister DefaultUserTemplateEmail RegistrationAdminEmail AllowAdminsToManageAdmins NotifyOnRegistration
    InvitationCode ReCaptchaSiteKey ReCaptchaMinScore
    CountryCodesForTimezones DefaultUserTimezone
    DefaultDateFormat DefaultTimeFormat DefaultDateTimeFormat
    nfs_store_default_app_type_id
    admin_nfs_role
    DefaultCountrySelect GdprCountryCodes
  ].freeze
end
