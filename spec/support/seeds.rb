# Support seeding the database
module Seeds
    
end

def auto_admin
  if @admin
    @admin = Admin.find_by_id(@admin.id) 
    return @admin if @admin
  end
  @admin, pw = ControllerMacros.create_admin
  @admin
end
