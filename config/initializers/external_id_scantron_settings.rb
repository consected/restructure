class Settings
  

  Scantron.external_id_attribute = :scantron_id
  Scantron.external_id_edit_pattern = '\\d{0,6}'
  Scantron.external_id_range = 1..999999  
  
  Scantron.add_to_app_list
end
