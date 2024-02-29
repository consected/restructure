# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    GdprTermsOfUseTemplate = 'ui new user registration terms gdpr'
    DefaultTermsOfUseTemplate = 'ui new user registration terms default'

    before_action :authorize_resource, only: %i[new create]

    before_action :devise_registration_params

    before_action :verify_invitation_code, only: [:create]

    private

    def sign_up(resource_name, resource)
      # must override with empty implementation,
      # so users do not sign-in automatically after sign-up (user registration)
    end

    def build_resource(hash = {})
      super

      resource.current_admin = RegistrationHandler.registration_admin
      resource.terms_of_use_accepted = terms_of_use_accepted(resource)
    end

    def devise_registration_params
      devise_parameter_sanitizer.permit(:sign_up, keys: %i[country_code first_name last_name terms_of_use client_localized])
    end

    def authorize_resource
      raise 'Users are not allow to register; contact the administrator.' unless Settings::AllowUsersToRegister
    end

    def verify_invitation_code
      inv = Settings::InvitationCode
      return unless inv

      raise FphsGeneralError, 'Incorrect invitation code' unless params[:invitation_code] == inv
    end

    def gdpr_country?(country_code)
      Settings::GdprCountryCodes.include?(country_code)
    end

    def terms_of_use_accepted_gdpr
      return @terms_of_use_gdpr if @terms_of_use_gdpr

      gdpr_template_id = Admin::MessageTemplate.find_by(name: GdprTermsOfUseTemplate).id
      @terms_of_use_gdpr = "message_templates|#{gdpr_template_id}|gdpr"
    end

    def terms_of_use_accepted_default
      return @terms_of_use_default if @terms_of_use_default

      default_template_id = Admin::MessageTemplate.find_by(name: DefaultTermsOfUseTemplate).id
      @terms_of_use_default = "message_templates|#{default_template_id}|default"
    end

    # @param [Object] resource
    # @return [String] terms of use
    def terms_of_use_accepted(resource)
      return unless resource.is_a?(User)

      return if resource.country_code.blank? # don't continue to set the value unless the country is selected
      return unless resource.terms_of_use.to_i == 1 # unless terms of use was checked

      if gdpr_country?(resource.country_code)
        terms_of_use_accepted_gdpr
      else
        terms_of_use_accepted_default
      end
    end
  end
end
