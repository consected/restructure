class Settings
  StartYearRange = 1900..(Date.current.year)
  EndYearRange = 1900..(Date.current.year)
  AgeRange = 1..150
  CareerYearsRange = 0..50

  PositiveIntPattern = '\\d+'.freeze
  AgePattern = '\\d{1,3}'.freeze
  YearFieldPattern = '\\d{4,4}'.freeze


  UserTimeout = 30.minutes.freeze
  AdminTimeout = 15.minutes.freeze

  OsWordsFile = "/usr/share/dict/words"
  PasswordEntropyConfig = {
    min_entropy: 20,
    min_word_length: 4,
    extra_dictionary_words: :word_list,
    use_dictionary: true
  }.freeze

end
