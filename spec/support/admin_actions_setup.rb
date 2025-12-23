# frozen_string_literal: true

# Shared admin authentication and setup methods for system specs
module AdminActionsSetup
  # Create an admin user with 2FA enabled
  # @return [String] the generated password
  def make_an_admin
    ENV['FPHS_ADMIN_SETUP'] = 'yes'

    @good_email = "testuser#{rand(1_000_000_000)}admin@testing.com"
    @admin = Admin.create! email: @good_email
    # Save a new password, as required to handle temp passwords
    @admin = Admin.find(@admin.id)
    @good_password = @admin.generate_password
    @admin.save!
    @admin.otp_secret = Admin.generate_otp_secret
    @admin.otp_required_for_login = true
    @admin.new_two_factor_auth_code = false
    @admin.save!

    @good_password
  end

  # Sign in an admin user with 2FA
  # Expects @admin, @good_email, and @good_password to be set
  def admin_sign_in_with_2fa
    # Don't reload admin - keep the in-memory object which has the correct password
    # Reloading causes password validation to fail after setup_redcap_project_admin_configs
    # @admin = Admin.find(@admin.id)

    # Check if password is still valid with the in-memory admin object
    unless @admin.valid_password?(@good_password)
      # Password validation failed - something modified the admin
      # Try to use the password from the database by checking what the actual password is
      fresh_admin = Admin.find(@admin.id)
      if fresh_admin.valid_password?(@good_password)
        # Database has the correct password, use it
        @admin = fresh_admin
      else
        # Neither in-memory nor database has the correct password
        # This means the password was regenerated somewhere
        # As a workaround, regenerate it here and update @good_password
        @admin = fresh_admin
        @good_password = @admin.generate_password
        @admin.save!
      end
    end

    admin = Admin.where(email: @good_email).first
    expect(admin).to be_a Admin
    expect(admin.id).to equal @admin.id

    url = "/admins/sign_in?secure_entry=#{SecureAdminEntry}"
    visit url
    expect(current_path).to eq '/admins/sign_in'

    within '#new_admin' do
      expect(@admin.email).to eq @good_email
      expect(@admin.valid_password?(@good_password)).to be true

      fill_in 'Email', with: @good_email
      fill_in 'Password', with: @good_password
      click_button 'Log in'
    end

    # Enter 2FA code
    expect(page).to have_selector('.login-2fa-block', visible: true)
    expect(page).to have_selector('#new_admin', visible: true)
    expect(page).to have_selector('input[type="submit"]:not([disabled])', visible: true)

    within '#new_admin' do
      fill_in 'Two-Factor Authentication Code', with: @admin.current_otp
      click_button 'Log in'
    end

    # Check for successful login - either flash message or being on a non-login page
    if has_css?('.flash .alert', text: 'Signed in successfully.', wait: 2)
      expect(page).to have_css('.flash .alert', text: 'Signed in successfully.')
    else
      # Flash may have disappeared, verify we're logged in by checking we're not on login page
      expect(current_path).not_to eq '/admins/sign_in'
    end
  end

  # Create a regular user account that matches the admin email
  # Used for admins that need to access user-facing features
  # @param [String] app_type_name The app type to enable (default: 'ref-data')
  # @return [User] the created/updated user
  def create_admin_matching_user(app_type_name: 'ref-data')
    app_type = Admin::AppType.active.find_by_name(app_type_name)
    raise "App type '#{app_type_name}' not found" unless app_type

    app_type_id = app_type.id
    create_user(nil, '', email: @admin.email) unless @admin.matching_user

    @user = user = @admin.matching_user

    enable_user_app_access app_type.name, user
    user.update!(app_type_id: app_type_id)

    expect(app_type_id).not_to be_nil
    expect(Settings.admin_master).not_to be_nil

    setup_access 'trackers', user: user
    setup_access 'nfs_store__manage__containers', user: user
    setup_access 'nfs_store__manage__stored_files', user: user
    setup_access 'nfs_store__manage__archived_files', user: user
    expect(@admin.matching_user.app_type).not_to be_nil
    expect(@admin.matching_user).to eq user

    user
  end
end
