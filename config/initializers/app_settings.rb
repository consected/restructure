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
    a = Admin.find_or_create_by email: 'auto-admin@dummy.aaa'    
  end
  
  def self.add_record_update_entries name
    puts "add_record_update_entries #{name}"
    protocol = Protocol.updates.first
    sp = protocol.sub_processes.find_by_name('record updates')
    values = []
    values << {name: "created #{name.downcase}", sub_process_id: sp.id}
    values << {name: "updated #{name.downcase}", sub_process_id: sp.id}
    
    # Allow the item to be created by the auto admin
    prev_val = ENV['FPHS_ADMIN_SETUP']
    ENV['FPHS_ADMIN_SETUP']='yes'
    
    values.each do |v|
      res = sp.protocol_events.find_or_initialize_by(v)
      unless res.admin
        res.update!(current_admin: auto_admin) 
        puts "Added protocol event #{v} in #{protocol.id} / #{sp.id}"
      else
        puts "Did not add protocol event #{v} in #{protocol.id} / #{sp.id}"
      end
    end
    # Clean up the admin authorization if not previously set
    ENV.delete 'FPHS_ADMIN_SETUP' unless prev_val
    
  end
end
