Rails.application.config.to_prepare do

  # Avoid URL guessing to get at the admin login page
  SecureAdminEntry = 'iuwqeryljksdajfghsdfj2382346ywdkjhf'
  DeviseController.send('before_action',
    ->{
      flash[:info] = 'you must be logged in as a user to access this page' and redirect_to '/' if request.path.start_with?('/admins/sign_in') && (!current_user && !current_admin && params[:secure_entry]!=SecureAdminEntry)
    }
  )

  # For two factor authentication
  DeviseController.send('before_action',
    ->{
      devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
    }
  )


end
