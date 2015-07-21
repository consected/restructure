module ControllerMacros
  def self.create_user
      @good_email = 'testuser-tester@testing.com'
      
      @user = User.create email: @good_email
      @good_password = @user.password
  end

  def self.create_admin
      @good_admin_email = 'testadmin-tester@testing.com'
      
      @admin = Admin.create email: @good_admin_email
      @good_admin_password = @admin.password
  end

  
  def before_each_login_user
    before(:each) do
      
      ControllerMacros.create_user

      request.env["devise.mapping"] = Devise.mappings[:user]
      @user = User.new email: @good_email, password: @good_password
      sign_in @user    
    end
  end
  
  def before_each_login_admin
    before(:each) do
      
      ControllerMacros.create_admin

      request.env["devise.mapping"] = Devise.mappings[:admin]
      @admin = User.new email: @good_admin_email, password: @good_admin_password
      sign_in @admin
    end
  end
end
