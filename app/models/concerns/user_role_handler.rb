# frozen_string_literal: true

# Simple concern to provide information about a user's access controls directly through
# the user instance. Simply unclutters the User model.
module UserRoleHandler
  extend ActiveSupport::Concern

  included do
    # Enforce use of app_type when getting user_roles, to prevent leakage of same named user roles across apps
    has_many :user_roles,
             ->(user) { user_app_type(user) },
             autosave: true, class_name: 'Admin::UserRole'

    after_save :clear_assoc_cache

    after_create :assign_roles_to_user
  end

  def clear_assoc_cache
    user_roles.reset
    Admin::UserRole.user_app_type(self).reset
    clear_role_names!
  end

  def assign_roles_to_user
    return if a_template_or_batch_user? || !allow_users_to_register?

    template_user = RegistrationHandler.registration_template_user
    template_user_roles = Admin::UserRole.active.where(user: template_user, app_type: Admin::AppType.active.all)
    app_types = template_user_roles.map(&:app_type)
    Admin::UserRole.copy_user_roles(template_user, self, app_types, current_admin)
  end
end
