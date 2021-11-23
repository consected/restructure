module Users
  class RegistrationsController < Devise::RegistrationsController

    before_action :devise_registration_params

    private

    def sign_up(resource_name, resource)
      # do not sign-in the user after sign-up (user registration)
      # empty implementation
    end

    def build_resource(hash = {})
      super
      self.resource.current_admin = RegistrationHandler.registration_admin
    end

    def devise_registration_params
      devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name])
    end

  end
end