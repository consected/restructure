class Settings
  
  ScantronIdPattern  = '\\d{0,6}'.freeze
  ScantronIdRange = (1..999999).freeze
  

  Scantron.add_to_app_list

end
