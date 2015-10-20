class Settings
  StartYearRange = 1900..(Date.current.year)
  EndYearRange = 1900..(Date.current.year)
  AgeRange = 1..150
  CareerYearsRange = 0..50
  
  PositiveIntPattern = '\\d+'.freeze
  
  YearFieldPattern = '\\d{4,4}'.freeze
  ScantronPattern = '\\d{0,6}'.freeze
  
  
  UserTimeout = 30.minutes.freeze
  AdminTimeout = 15.minutes.freeze
  
  ScantronIdPattern  = '\\d{0,6}'
  ScantronIdRange = 1..999999
  
end
