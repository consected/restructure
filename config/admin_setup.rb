module AdminSetup

  
  def self.setup admins_string
    
    puts "No admin string specified in env FHPS_ADMINS" and return if admins_string.blank?
    
    admins = admins_string.split(';')
    op = ""
    admins.each do |admin|
      
      admin_obj = Admin.where(email: admin).first
      if admin_obj
        
        admin_obj.force_password_reset

        admin_obj.save
        op << "Existing Admin (#{admin}) updated with new password: #{admin_obj.new_password}\n"
      else  
        admin_obj = Admin.create(email: admin)
        op << "Admin (#{admin}) password: #{admin_obj.new_password}\n"
      end
    end

    puts op  
  end
  
  def self.remove admins_string
    
    admins = admins_string.split(';')
    op = ""
    admins.each do |admin|
      admin_obj = Admin.where(email: admin).first
      if admin_obj
        
        # An admin is not truly removed from the database,
        # just marked as disabled
        admin_obj.disable!
        
        op << "Removed: #{admin}\n"
      else
        op << "Admin not recognized: #{admin}\n"
      end
    end
    puts op  
  end

  def self.run
    action = ENV['FHPS_ACTION']
    admins = ENV['FHPS_ADMINS']
    msg = ""
    if admins.blank? || action.blank?
      msg = <<EOF

Add, update or remove admin users from the FHPS app
  
Usage:

Add / update admins:
RAILS_ENV=production FHPS_ACTION=add FHPS_ADMINS='admin1@ex.com;admin2@ex.com' rails runner config/admin_setup.rb

Will create any specified admins not already existing with a default password
and update any specified admins that exist, assigning them a new password
  
Remove admins:
  
RAILS_ENV=production FHPS_ACTION=remove FHPS_ADMINS='admin1@ex.com;admin2@ex.com' rails runner config/admin_setup.rb

Will remove any specified admins from the admin list. 
  
EOF
      puts msg
    end

    action = ENV['FHPS_ACTION']

    if action == 'remove'
      AdminSetup.remove admins
    elsif action == 'add'
      AdminSetup.setup admins
    else
      puts "FHPS_ACTION not recognized.\n#{msg}"
    end
  end
  
  run
  
end

