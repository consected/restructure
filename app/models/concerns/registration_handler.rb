module RegistrationHandler
  extend ActiveSupport::Concern

  def allow_users_to_register?
    @allow_users_to_register ||= Settings::ALLOW_USERS_TO_REGISTER
    @allow_users_to_register && is_a?(User)
  end

  # The registration admin is assigned to newly created user through the user registration feature.
  def self.registration_admin
    Admin.find_by(email: Settings::DEFAULT_ADMIN_TEMPLATE_EMAIL)
  end

  # The registration user is the template (cookie-cutter) for creating new users.
  # Admins must create a template user with roles and app_types through the admin dashboard.
  # The DEFAULT_USER_TEMPLATE_EMAIL must be set as an environment variable.
  def self.registration_template_user
    User.find_by(email: Settings::DEFAULT_USER_TEMPLATE_EMAIL)
  end

end