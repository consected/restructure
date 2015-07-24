require 'support/seed_support'
module ModelSupport
  
  def seed_database
    SeedSupport.setup
  end
  
  def create_user
    a = User.all.last
    r = 1
    r = a.id + 10 if a
    good_email = "testuser-tester-#{r}@testing.com"
    user = User.create! email: good_email        
    good_password = user.password
    @user = user
    [user, good_password]
    
  end

  def create_admin
    a = Admin.last
    r = 1
    r = a.id+1 if a
    good_admin_email = "testadmin-tester#{r}@testing.com"

    admin = Admin.create! email: good_admin_email
    good_admin_password = admin.password
    @admin = admin
    [admin, good_admin_password]
  end    
end
