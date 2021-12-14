# frozen_string_literal: true

module RegistrationHandler
  extend ActiveSupport::Concern

  included do
    after_create :send_confirmation
  end

  # @return [TrueClass, FalseClass]
  def allow_users_to_register?
    @allow_users_to_register ||= Settings::AllowUsersToRegister
    @allow_users_to_register && is_a?(User)
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

  def send_confirmation
    Users::Confirmations.notify(self) if allow_users_to_register?
  end
end
