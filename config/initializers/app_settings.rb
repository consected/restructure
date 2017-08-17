class Settings
  StartYearRange = 1900..(Date.current.year)
  EndYearRange = 1900..(Date.current.year)
  AgeRange = 1..150
  CareerYearsRange = 0..50
  
  PositiveIntPattern = '\\d+'.freeze
  
  YearFieldPattern = '\\d{4,4}'.freeze
  
  
  UserTimeout = 30.minutes.freeze
  AdminTimeout = 15.minutes.freeze
  
  def self.auto_admin 
    Admin.find_or_create_by email: 'auto-admin@dummy.aaa'    
  end
  
  def self.add_record_update_entries name

    # Allow the item to be created by the auto admin
    prev_val = ENV['FPHS_ADMIN_SETUP']
    ENV['FPHS_ADMIN_SETUP']='yes'

    Tracker.add_record_update_entries name, auto_admin

    # Clean up the admin authorization if not previously set
    ENV.delete 'FPHS_ADMIN_SETUP' unless prev_val
    
  end
end
