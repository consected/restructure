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
  end
end
