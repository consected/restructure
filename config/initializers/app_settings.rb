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

end
