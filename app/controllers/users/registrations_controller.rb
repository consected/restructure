# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    before_action :authorize_resource, only: %i[new create]

    before_action :devise_registration_params

    before_action :verify_invitation_code, only: [:create]

    private

    # TODO: move to a concern
    def gdpr_country?(country_code)
      %w[AT BE BG HR CY CZ DK EE FI FR DE GR HU IE IT LV LU MT NL PL PT RO SK SI ES SW GB].include?(country_code)
    end

    def sign_up(resource_name, resource)
      # must override with empty implementation,
      # so users do not sign-in automatically after sign-up (user registration)
    end

    def build_resource(hash = {})
      super
      resource.current_admin = RegistrationHandler.registration_admin

      return unless resource.is_a?(User)

      resource.terms_of_use_accepted = if gdpr_country?(resource.country_code)
                                         Settings::GdprTermsOfUseTemplate
                                       else
                                         Settings::DefaultTermsOfUseTemplate
                                       end
    end

    def devise_registration_params
      devise_parameter_sanitizer.permit(:sign_up, keys: %i[country_code first_name last_name terms_of_use])
    end

    def authorize_resource
      raise 'Users are not allow to register; contact the administrator.' unless Settings::AllowUsersToRegister
    end

    def verify_invitation_code
      inv = Settings::InvitationCode
      return unless inv

      raise FphsGeneralError, 'Incorrect invitation code' unless params[:invitation_code] == inv
    end
  end
end
