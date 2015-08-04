require 'support/seed_support'

module ControllerMacros
  
  def self.create_user
    a = User.order(id: :desc).first
    r = 1
    r = a.id + 1 if a
    good_email = "ctestuser-tester-#{r}@testing.com"
    
    admin, pwa = create_admin
    
    user = User.create! email: good_email, admin: admin
    good_password = user.password
    
    [user, good_password]
    
  end

  def self.create_admin
    a = Admin.order(id: :desc).first
    r = 1
    r = a.id + 1 if a
    good_admin_email = "ctestadmin-tester#{r}@testing.com"

    admin = Admin.create! email: good_admin_email
    good_admin_password = admin.password
    
    [admin, good_admin_password]
  end
 
  def before_each_login_user 
    before(:each) do
      SeedSupport.setup      
      
      user, pw = ControllerMacros.create_user
      @request.env["devise.mapping"] = Devise.mappings[:user]
      
      Rails.logger.info "Attempting to sign in new user with email #{user.email} and password #{pw}"
      res = sign_in user                
      @user = user
      Rails.logger.info "Result: #{res}"
    end
  end
  
  def before_each_login_admin
    before(:each) do
      
      admin, pw = ControllerMacros.create_admin

      @request.env["devise.mapping"] = Devise.mappings[:admin]
      
      sign_in admin
      
      @admin = admin
    end
  end
  
  def before_each_create_address
    @address = ControllerMacros.create_address @user
  end
  
end
