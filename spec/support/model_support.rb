require 'support/seed_support'
module ModelSupport
  
  UserPrefix = 'g-ttuser-'
  UserDomain = 'testing.com'
  
  def seed_database
    Rails.logger.info "Starting seed setup"
    SeedSupport.setup
  end
  
  def gen_username r
    
    "#{UserPrefix}#{r}@#{UserDomain}"
  end
  
  def create_user r=nil, extra=''
    
    unless r      
      r = Time.new.to_f.to_s 
    end
    good_email = gen_username("#{r}-#{extra}-")
    
    #puts "Attempting to create user with with name #{good_email}. #{User.find_by_email(good_email).inspect}"
    admin, pwa = create_admin
    user = User.create! email: good_email, current_admin: admin
    good_password = user.password
    @user = user
    [user, good_password]    
  end

  def create_admin  r=nil
    a = Admin.order(id: :desc).first
    unless r
      r = 1
      r = a.id + 1 if a
    end
    good_admin_email = "d-testadmin-tester#{r}@testing.com"

    admin = Admin.create! email: good_admin_email
    good_admin_password = admin.password
    @admin = admin
    [admin, good_admin_password]
  end    
end
