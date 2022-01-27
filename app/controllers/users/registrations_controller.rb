# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    before_action :authorize_resource, only: %i[new create]

    before_action :devise_registration_params

    private

    def sign_up(resource_name, resource)
      # must override with empty implementation,
      # so users do not sign-in automatically after sign-up (user registration)
    end

    def build_resource(hash = {})
      super
      resource.current_admin = RegistrationHandler.registration_admin
    end

    def devise_registration_params
      devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name])
    end

    def authorize_resource
      raise 'Users are not allow to register; contact the administrator.' unless Settings::AllowUsersToRegister
    end
  end

end
