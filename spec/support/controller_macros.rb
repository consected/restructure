require "#{::Rails.root}/spec/support/seed_support"

module ControllerMacros

  def self.create_user opt={}
    a = User.all.unscope(:where, :order).order(id: :desc).first
    r = 1
    r = a.id + 1 if a
    good_email = "ctestuser-tester-#{r}@testing.com"

    admin, _ = create_admin

    user = User.create! email: good_email, current_admin: admin

    app_type = Admin::AppType.active.first

    unless opt[:no_app_type_setup]
      Admin::UserAccessControl.create! user: user, app_type: app_type, access: :read, resource_type: :general, resource_name: :app_type, current_admin: admin
    end

    # Set a default app_type to use to allow non-interactive tests to continue
    user.app_type = app_type
    user.save!

    # Save a new password, as required to handle temp passwords
    user  = User.find(user.id)
    good_password = user.generate_password
    user.current_admin = admin
    user.otp_required_for_login = true
    user.new_two_factor_auth_code = true
    user.save!

    [user, good_password]

  end

  def self.create_admin
    a = Admin.order(id: :desc).first
    r = 1
    r = a.id + 1 if a
    good_admin_email = "ctestadmin-tester#{r}@testing.com"

    admin = Admin.create! email: good_admin_email

    # Save a new password, as required to handle temp passwords
    admin = Admin.find(admin.id)
    good_admin_password = admin.generate_password
    admin.otp_secret = Admin.generate_otp_secret

    admin.otp_required_for_login = true
    admin.new_two_factor_auth_code = true

    admin.save!

    [admin, good_admin_password]
  end

  def before_each_login_user
    before(:each) do
      SeedSupport.setup

      user, pw = ControllerMacros.create_user
      @request.env["devise.mapping"] = Devise.mappings[:user]

      Rails.logger.info "Attempting to sign in new user with email #{user.email} and password #{pw}"
      res = sign_in user
      user.app_type = Admin::AppType.all_available_to(user).first
      user.save!
      @user = user
      Rails.logger.info "Result: #{res}"
    end
  end

  def before_each_login_admin
    before(:each) do

      admin, _ = ControllerMacros.create_admin

      @request.env["devise.mapping"] = Devise.mappings[:admin]

      sign_in admin

      @admin = admin
    end
  end

  def before_each_create_address
    @address = ControllerMacros.create_address @user
  end

end
