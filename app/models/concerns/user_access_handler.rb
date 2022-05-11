# frozen_string_literal: true

# Simple concern to provide information about a user's access controls directly through
# the user instance. Simply unclutters the User model.
module UserAccessHandler
  extend ActiveSupport::Concern

  included do
    has_many :user_access_controls, autosave: true, class_name: 'Admin::UserAccessControl'
    before_save :set_access_levels
  end

  #
  # Simple authorizations that say what type of general actions a user can perform in this app type.
  # In previous versions, this was managed by the UserAuthorization class. Since
  # we now have App Types and user access controls, this has been combined.
  # The can? method defaults to resource_type :general for this reason, although
  # can be used for checking access on other resource types if desired
  # example: user.can? :create_master
  # @param [Symbol] auth - the resource name to check against
  # @param [Symbol] resource_type - defaults to :general - one of Admin::UserAccessControl.resource_types
  def can?(auth, resource_type = :general)
    has_access_to? :access, resource_type, auth
  end

  #
  # Preferred mechanism for checking access controls for a user
  # Memoizes the result in param @has_access_to, which gets cleared
  # if a user access control is added or updated while this instance is present.
  # Note: with_options usage is vague and should be avoided
  # @param [Symbol] perform - the action to be performed such as :access or :create
  # @param [Symbol] resource_type - one of Admin::UserAccessControl.resource_types
  # @param [Symbol] named - the resource name to check against
  # @param [unknown] with_options - do not use
  # @param [Admin::AppType | Integer] alt_app_type_id - by default check against user's current app type,
  #                                   otherwise use this alternative
  # @param [True | nil] force_reset - force reset of memoization to reevaluate
  # @return [Admin::UserAccessControl | nil]
  def has_access_to?(perform, resource_type, named, with_options = nil, alt_app_type_id: nil, force_reset: nil)
    @has_access_to ||= {}

    clear_has_access_to! if user_access_controls_updated?
    clear_role_names! if user_roles_updated?

    key = "#{perform}-#{resource_type}-#{named}-#{with_options}-#{alt_app_type_id || app_type_id}"
    return @has_access_to[key] if @has_access_to.key?(key) && !force_reset

    @has_access_to[key] =
      Admin::UserAccessControl.access_for? self,
                                           perform,
                                           resource_type,
                                           named,
                                           with_options,
                                           alt_app_type_id: alt_app_type_id
  end

  #
  # The full list of active role names for the current app_type
  # @return [Array{String}]
  def role_names
    clear_role_names! if @latest_user_role != Admin::UserRole.latest_update

    @role_names ||= user_roles.active.pluck(:role_name)
  end

  #
  # Is there a later user access control record (updated at or created at) than
  # the one we last saw within this instance. Handles automatic memo clearing to
  # support changes to user access controls in spec tests
  def user_access_controls_updated?
    if @latest_user_access_control != Admin::UserAccessControl.latest_update
      @latest_user_access_control = Admin::UserAccessControl.latest_update
    else
      false
    end
  end

  #
  # Is there a later user role record (updated at or created at) than
  # the one we last saw within this instance. Handles automatic memo clearing to
  # support changes to user roles in spec tests
  def user_roles_updated?
    @latest_user_role != Admin::UserRole.latest_update
  end

  def clear_has_access_to!
    @latest_user_access_control = Admin::UserAccessControl.latest_update(force: true)
    @has_access_to = {}
  end

  def clear_role_names!
    @latest_user_role = Admin::UserRole.latest_update(force: true)
    @role_names = nil
    # Updated roles also lead to has_access_to evaluations requiring refresh
    clear_has_access_to!
  end

  protected

  # Ensure that access controls are appropriately created and disabled
  # Disable access controls when a user is disabled.
  # Do not re-enable automatically, since this could provide undesired access being granted
  def set_access_levels
    user_access_controls.each(&:disable!) if persisted? && disabled
  end
end
