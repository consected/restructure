# frozen_string_literal: true

class Admin::UserAccessControl < Admin::AdminBase
  self.table_name = 'user_access_controls'

  include AdminHandler
  include AppTyped
  include UserAndRoles

  belongs_to :user, optional: true

  validate :correct_access_valid?

  attr_accessor :allow_bad_resource_name

  #
  # Valid resource types
  # NOTE: external_id_assignments is deprecated and should not be used
  def self.resource_types
    %i[table general limited_access report standalone_page activity_log_type external_id_assignments]
  end

  #
  # access levels provide a distinct scale of control for each resource type
  # for a specific named resource a user is only assigned a single access level
  # For example, on a table, a user is able to only read the table if he has :read, :update or :create
  # Another user may read or update the table if she has :update, or :create
  # A user may only create records on a table if she has :create
  def self.access_levels
    {
      table: [nil, :see_presence, :read, :update, :create],
      general: [nil, :read],
      limited_access: [nil, :limited, :limited_if_none],
      report: [nil, :read],
      standalone_page: [nil, :read],
      activity_log_type: [nil, :see_presence, :read, :update, :create],
      external_id_assignments: [nil, :limited, :limited_if_none]
    }
  end

  #
  # Check an access level is valid for the specified resource type
  def self.valid_access_level?(on_resource_type, can_perform)
    can_perform = can_perform.to_sym if can_perform.respond_to? :to_sym
    res = access_levels[on_resource_type.to_sym]
    res&.include? can_perform
  end

  #
  # Scope result of a query to only return valid resources, not those that no longer exist
  def self.valid_resources
    # Return if everything is not setup yet
    return active unless Master.respond_to? :get_all_associations

    rnft = resource_names_by_type

    ids = []
    active.each do |r|
      ids << r.id if r.bad_resource_name(rnft)
    end

    if ids.present?
      active.where(['id not in (?)', ids])
    else
      active
    end
  end

  #
  # combo levels provide a convenient way to check for common access control patterns.
  # Can a user access a resource? Yes, if they have any level of read or above
  # Can a user edit a resource? Yes, if they have any level of update or above
  def self.combo_levels
    {
      table: {
        access: %i[read update create],
        see_presence_or_access: %i[see_presence read update create],
        edit: %i[update create]
      },
      general: {
        access: [:read]
      },
      report: {
        access: [:read]
      },
      standalone_page: {
        access: [:read]
      },
      activity_log_type: {
        access: %i[read update create],
        see_presence_or_access: %i[see_presence read update create],
        edit: %i[update create]
      }
    }
  end

  #
  # List of resource name for the specified resource type
  # Provide both forms of identifier for the reports, to allow deprecated
  # app configurations to continue working
  # @param [String] resource_type
  # @return [Array{String}]
  def self.resource_names_for(resource_type)
    if resource_type == :report
      active_reports = Report.active
      return active_reports.map(&:alt_resource_name) + active_reports.map(&:name) + ['_all_reports_']
    end

    Resources::UserAccessControl.resource_names_for(resource_type)
  end

  #
  # Is the combination access level valid for the resource type?
  # @param [String | Symbol] on_resource_type
  # @param [String | Symbol | Array] can_perform - will exit immediately with an Array
  # @return [Boolean]
  def self.valid_combo_level?(on_resource_type, can_perform)
    return if can_perform.nil? || can_perform.is_a?(Array)

    res = combo_levels[on_resource_type.to_sym]
    can_perform = can_perform.to_sym if can_perform.respond_to? :to_sym
    res[can_perform] if res
  end

  #
  # Hash of resource names keyed by resource type
  # @return [Hash]
  def self.resource_names_by_type
    rn = {}
    resource_types.each do |k|
      rn[k] = resource_names_for(k).sort
    end
    rn
  end

  #
  # Currently unused
  def self.options
    nil
  end

  #
  # Find out if the user can perform a specific action on a named resource type in his current app type
  # Optionally provide can_perform=nil to find a record for any access level or
  # an array to check for multiple possible options
  # If it is necessary to check for access to a resource on an app type that is not the user's current one,
  # or the user is nil, specify the alt_app_type_id
  # Similarly, an alt_role_name can be specified
  # @param [User] user
  # @param [nil | Array | Symbol] can_perform - access level (Array or Symbol) or combo access level (Symbol)
  # @param [Symbol | String] on_resource_type - valid resource type
  # @param [Symbol | String] named - resource name
  # @param [nil] with_options - not used - will raise an exception if set
  # @param [Admin::AppType | Integer] alt_app_type_id - app type or ID for the app type to
  #                                                     apply to if the user does not have a current app_type set
  # @param [String] alt_role_name - for an Admin::UserRole when the role control is to override the default controls
  # @param [Hash] add_conditions - additional conditions to apply to scoped user and roles
  # @return [Admin::UserAccessControl | nil]
  def self.access_for?(user, can_perform, on_resource_type, named, with_options = nil,
                       alt_app_type_id: nil, alt_role_name: nil, add_conditions: nil)
    raise FphsException, 'Options can not be added to access_for?' if with_options

    app_type_id = alt_app_type_id.is_a?(Admin::AppType) ? alt_app_type_id.id : alt_app_type_id
    app_type_id ||= user&.app_type_id
    cache_key = "#{user&.id}-#{can_perform}-#{on_resource_type}-#{named}-#{app_type_id}-#{alt_role_name}-#{add_conditions}"
    res = Rails.cache.fetch(cache_key) do
      evaluate_access_for(user, can_perform, on_resource_type, named, app_type_id,
                          alt_role_name: alt_role_name,
                          add_conditions: add_conditions)
    end

    return unless res

    find(res)
  end

  # @param [User] user
  # @param [nil | Array | Symbol] can_perform - access level (Array or Symbol) or combo access level (Symbol)
  # @param [Symbol | String] on_resource_type - valid resource type
  # @param [Symbol | String] named - resource name
  # @param [Admin::AppType | Integer] alt_app_type_id - app type or ID for the app type to
  #                                                     apply to if the user does not have a current app_type set
  # @param [String] alt_role_name - for an Admin::UserRole when the role control is to override the default controls
  # @param [Hash] add_conditions - additional conditions to apply to scoped user and roles
  # @return [id | nil] - id of the UserAccessControl
  def self.evaluate_access_for(user, can_perform, on_resource_type, named, app_type_id,
                               alt_role_name: nil, add_conditions: nil)

    if can_perform
      unless can_perform.is_a?(Array) ||
             valid_access_level?(on_resource_type, can_perform) ||
             valid_combo_level?(on_resource_type, can_perform)
        raise FphsException, "Access level #{can_perform} does not exist for resource type #{on_resource_type}"
      end

      # Get a combo of levels if one exists, otherwise use the provided value
      c = combo_levels[on_resource_type][can_perform] if valid_combo_level?(on_resource_type, can_perform)
      can_perform = c || can_perform
    end

    primary_conditions = { resource_type: on_resource_type, resource_name: named }

    # Get the user's own access first, roles next, and the fallback of null last. If the
    # user does not have her own access, then if she is a member of role_name, that'll be used and finally
    # the default for the app type will return instead,
    # so that .first is always the most appropriate value
    res = where(primary_conditions).scope_user_and_role(user, app_type_id, alt_role_name)
    res = res.where(add_conditions) if add_conditions
    res = res.first

    if res && can_perform
      can_perform = [can_perform] unless can_perform.is_a? Array
      res_access = nil
      res_access = res.access.to_sym if res.access
      return nil unless res_access.in?(can_perform)
    end

    res&.id
  end

  #
  # Create a user access control with a template role, to
  # ensure that an item is correctly exported from an app type, even
  # if no real end users or roles have been applied to it.
  # Will update an existing user access control if it already exists.
  def self.create_template_control(admin, app_type, resource_type, resource_name, default_access: :read, disabled: nil)
    # Fails quietly if the item already exists
    Admin::UserRole.create(role_name: Settings::AppTemplateRole, app_type: app_type, user: User.template_user,
                           current_admin: admin)

    uac = Admin::UserAccessControl.where(role_name: Settings::AppTemplateRole, app_type: app_type,
                                         resource_type: resource_type, resource_name: resource_name).first

    if uac
      uac.update(role_name: Settings::AppTemplateRole, app_type: app_type, resource_type: resource_type,
                 resource_name: resource_name, access: default_access, disabled: disabled, current_admin: admin)
    else
      Admin::UserAccessControl.create(role_name: Settings::AppTemplateRole, app_type: app_type,
                                      resource_type: resource_type, resource_name: resource_name, access: default_access, disabled: disabled, current_admin: admin)
    end
  end

  #
  # Check which tables a user can view in the current app type, or an alternative app type if specified
  def self.viewable_tables(user, alt_app_type_id: nil)
    view = {}
    resource_names_for(:table).each do |r|
      view[r.to_sym] = !!access_for?(user, :access, :table, r, alt_app_type_id: alt_app_type_id)
    end

    view
  end

  #
  # Get list of controls for the external_id_assignments / limited_access type in the user's current app.
  # Get both the user's override, if it exists, and the default for each resource,
  # which we then filter down to the actual access control
  # If there are no restrictions for this user in this app, just return nil
  def self.limited_access_restrictions(user)
    primary_conditions = { resource_type: %i[external_id_assignments limited_access] }

    res = where(primary_conditions).order(resource_name: :asc).scope_user_and_role(user)

    res_length = res.length
    return unless res_length > 0

    r_prev = nil
    delist = []
    # Filter out later repeats in the list if they have matching resource_names
    # This ensures the precedence of the defined limited access controls works as expected.
    # while allowing controls on multiple resources to be defined
    (0..res_length - 1).each do |i|
      if r_prev && r_prev.app_type_id == res[i].app_type_id && r_prev.resource_name == res[i].resource_name
        delist << i
      else
        r_prev = res[i]
      end
    end

    delist.each do |i|
      res[i].access = 'remove'
    end

    # select only those with access set, since nil access means the resource can be accessed.
    res = res.select { |r| r.access && r.access != 'remove' }

    return if res.empty?

    res
  end

  #
  # Check if a resource name is bad.
  # For example, the resource definition may have been disabled since the access was set up,
  # so although originally valid, the resource name is no longer valid.
  def bad_resource_name(cache_resource_names_for_type = nil)
    return if disabled
    return true if !respond_to?(:resource_name) || resource_name.nil? || resource_type.nil?

    resource_name_for_type = if cache_resource_names_for_type
                               cache_resource_names_for_type[resource_type.to_sym]
                             else
                               self.class.resource_names_for(resource_type.to_sym)
                             end

    !resource_name_for_type&.include?(resource_name.to_s)
  end

  private

  #
  # Validation method to ensure the user access control has been configured correctly:
  # - any settings are allowed if disabled
  # - disabled must be set if the user is disabled
  # - the resource type is one of the valid options
  # - a valid access level has been provided for the resource type
  # - the resource name if not a valid resource for the resource type
  # - another user access control with this user, resource name & type, role name and app type
  #   does not already exist
  def correct_access_valid?
    self.access = nil if access.blank?
    if disabled
      true
    elsif user&.disabled && !disabled
      errors.add :disabled, 'flag of an access control must be disabled, since the user is disabled'
    elsif resource_type.nil? || !self.class.resource_types.include?(resource_type.to_sym)
      errors.add :resource_type, 'is an invalid value'
    elsif !self.class.valid_access_level?(resource_type.to_sym, access)
      errors.add :access, 'is an invalid value'
    elsif !allow_bad_resource_name && (
            resource_name.nil? || !self.class.resource_names_for(resource_type.to_sym).include?(resource_name.to_s)
          )
      errors.add :resource_name, "is an invalid value (#{resource_name} in #{resource_type})"
    elsif !disabled
      res = self.class.access_for? user, nil, resource_type, resource_name, alt_role_name: role_name,
                                                                            alt_app_type_id: app_type_id
      if res && res.id != id # If we have a result and it is not this record
        if user_id && user_id == res.user_id # If the user has the authorization set
          errors.add :user,
                     "already has the access control #{access} on #{resource_type} #{resource_name} #{app_type ? app_type.name : ''} #{options}"
        elsif !user_id && res.user_id.nil? && role_name == res.role_name # If the new record has no user set and has a matching role _name
          errors.add :user_access_control,
                     "already exists for #{role_name} #{access} on #{resource_type} #{resource_name} #{app_type ? app_type.name : ''} #{options}"
        end
      end
    end
  end
end
