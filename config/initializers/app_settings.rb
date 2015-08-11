class Settings
  StartYearRange = 1900..(Date.current.year)
  EndYearRange = 1900..(Date.current.year)
  
  
  YearFieldPattern = '\\d{4,4}'.freeze
  ScantronPattern = '\\d{0,6}'.freeze
  
  UserTimeout = 30.minutes.freeze
  AdminTimeout = 5.minutes.freeze
end