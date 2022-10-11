# frozen_string_literal: true

#
# Provide the ability for the login page to check if a user or admin has
# completed the setup of their 2FA. Handles servers that have 2FA enabled or disabled.
# Provides a default response even if users are not found, to avoid malicious trawling of the app
# for valid users.
class MfaController < ApplicationController
  def step1
    return not_found unless request.post?

    return not_found if request.format.to_sym != :json

    resource = case resource_type
               when :user
                 User
               when :admin
                 Admin
               else
                 bad_request
                 return
               end

    begin
      email = permitted_params[:email]
      password = permitted_params[:password]
    rescue StandardError => e
      Rails.logger.warn "MFA request - #{e}"
    end

    if email.blank? || password.blank?
      bad_request
      return
    end

    if resource.two_factor_auth_disabled
      need_2fa = false
    else
      got = resource.active.find_by(email: email)

      # Don't actually return a failed validation at this point,
      # Since we need both password and 2FA to complete the authentication,
      # and want to avoid password guessing without a 2FA code being provided.
      got = nil unless got&.valid_password?(password)

      # If the user was not found, still require 2FA to prevent unauthorized attempts to identify registered users
      need_2fa = !got || got.otp_required_for_login
    end

    render json: { need_2fa: need_2fa }
  end

  private

  def resource_type
    params[:resource_type]&.to_sym
  end

  def permitted_params
    params.require(resource_type).permit(:email, :password)
  end

  def no_action_log
    true
  end
end
