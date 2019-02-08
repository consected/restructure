Rails.application.config.to_prepare do

  # Avoid URL guessing to get at the admin login page
  SecureAdminEntry = 'iuwqeryljksdajfghsdfj2382346ywdkjhf'
  DeviseController.send('before_action',
    ->{
      flash[:info] = 'you must be logged in as a user to access this page' and
      redirect_to '/' if request.path.start_with?('/admins/sign_in') &&
                          (!current_user && !current_admin && params[:secure_entry]!=SecureAdminEntry)
    }
  )

  # For two factor authentication
  DeviseController.send('before_action',
    ->{
      devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
    }
  )

  # Handle delivery of new 2FA token configuration
  DeviseController.send('before_action',
    -> {
      return unless signed_in?

      @resource = current_admin || current_user
      @resource_name = @resource.class.name.downcase


      if controller_name == 'registrations' && action_name.in?(['show_otp', 'test_otp'])
        return
      elsif controller_name == 'sessions' && action_name == 'destroy'
        return
      else
        redirect_to "/#{@resource_name.pluralize}/show_otp" if @resource.otp_secret.present? && !@resource.otp_required_for_login
      end
    }
  )


  DeviseController.send(:define_method, :show_otp) do
    redirect_to '/' and return unless signed_in?
    @resource = current_admin || current_user

    redirect_to '/' and return unless @resource && @resource.otp_secret.present? && !@resource.otp_required_for_login
    @resource_name = @resource.class.name.downcase
    # A secret was previously generated, and the user has not yet confirmed it (so it is not set as "required for login")
    # Continue with the action
  end

  DeviseController.send(:define_method, :test_otp) do
    redirect_to '/' unless signed_in?
    @resource = current_admin || current_user
    @resource_name = @resource.class.name.downcase

    code = params[:otp_attempt]

    res = @resource.validate_one_time_code code

    flash[:notice] = 'One-Time Code was incorrect. Please try again.' unless res

    redirect_to '/'
  end


  Warden::Manager.send(:after_authentication) do |record, warden, options|

    if record.respond_to?(:need_change_password?) && record.need_change_password?
      scope = options[:scope]
      warden.logout(scope)
      throw(:warden, :scope => scope, :reason => "Your password has expired.", :message => "Your password has expired. Contact the administrator to reset your account.")
    end
  end

end
