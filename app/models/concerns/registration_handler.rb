# frozen_string_literal: true

module RegistrationHandler
  extend ActiveSupport::Concern

  included do
    before_create :auto_confirm_if_not_self_registration
  end

  # @return [TrueClass, FalseClass]
  def allow_users_to_register?
    @allow_users_to_register ||= Settings::AllowUsersToRegister
    @allow_users_to_register && is_a?(User)
  end

  def self_registration_admin?
    current_admin == RegistrationHandler.registration_admin
  end

  def a_template_or_batch_user?
    email.end_with?(Settings::TemplateUserEmailPattern) || email == Settings::BatchUserEmail
  end

  #
  # Certain validations and notifications are required for self registering users.
  # To determine if a user is self registering, check if:
  #  - users are allowed to register (based on Settings)
  #  - the user is not a batch or template user (based on the email address pattern or matching the batch admin email)
  #  - the current admin setting up this user is the self registration admin (based on Settings)
  def required_for_self_registration?
    allow_users_to_register? && !a_template_or_batch_user? && self_registration_admin?
  end

  # The registration admin is assigned to newly created user through the user registration feature.
  # @return Admin
  def self.registration_admin
    Admin.find_by(email: Settings::RegistrationAdminEmail)
  end

  # The registration user is the template (cookie-cutter) for creating new users.
  # Admins must create a template user with roles and app_types through the admin dashboard.
  # The DEFAULT_USER_TEMPLATE_EMAIL must be set as an environment variable.
  # @return User
  def self.registration_template_user
    User.find_by(email: Settings::DefaultUserTemplateEmail)
  end

  private

  def auto_confirm_if_not_self_registration
    return if required_for_self_registration?

    self.confirmed_at = Time.now
  end
end
