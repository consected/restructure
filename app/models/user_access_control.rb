class UserAccessControl < ActiveRecord::Base

  include AdminHandler
  include AppTyped

  belongs_to :user

  validate :correct_access

  # access levels provide a distinct scale of control for each resource type
  # for a specific named resource a user is only assigned a single access level
  # For example, on a table, a user is able to only read the table if he has :read, :update or :create
  # Another user may read or update the table if she has :update, or :create
  # A user may only create records on a table if she has :create

  def self.access_levels
    {
      table: [nil, :read, :update, :create]
    }
  end

  def self.valid_access_level? on_resource_type, can_perform
    can_perform = can_perform.to_sym if can_perform.respond_to? :to_sym
    res = access_levels[on_resource_type.to_sym]
    res.include? can_perform if res
  end

  # combo levels provide a convenient way to check for common access control patterns.
  # Can a user access a resource? Yes, if they have any level of read or above
  # Can a user edit a resource? Yes, if they have any level of update or above
  def self.combo_levels
    {
      table: {
        access: [:read, :update, :create],
        edit: [:update, :create],
      }
    }
  end

  def self.valid_combo_level? on_resource_type, can_perform
    return if can_perform.nil? || can_perform.is_a?(Array)
    res = combo_levels[on_resource_type.to_sym]
    can_perform = can_perform.to_sym if can_perform.respond_to? :to_sym
    res[can_perform] if res
  end


  def self.resource_types
    [:table, :activity_log_record_type]
  end

  def self.resource_names
    Master.get_all_associations + ['item_flags']
  end

  def self.options
    nil
  end

  # Find out if the user can perform a specific action on a named resource type in his current app type
  # Optionally provide can_perform=nil to find a record for any access level or
  # an array to check for multiple possible options
  # If it is necessary to check for access to a resource on an app type that is not the user's current one,
  # or the user is nil, specify the alt_app_type_id
  def self.access_for? user, can_perform, on_resource_type, named, with_options=nil, alt_app_type_id: nil

    app_type_id = alt_app_type_id || user.app_type_id

    # Setup the user list of the desired user and nil, to allow fallback to nil if the user doesn't
    # have the requested access under his own identity
    user_list = [user, nil]

    conditions = {user: user_list, resource_type: on_resource_type, resource_name: named, app_type_id: app_type_id}
    conditions[:options] = with_options if with_options
    if can_perform
      unless can_perform.is_a?(Array) || valid_access_level?(on_resource_type, can_perform) || valid_combo_level?(on_resource_type, can_perform)
        raise FphsException.new "Access level #{can_perform} does not exist for resource type #{on_resource_type}"
      end

      # Get a combo of levels if one exists, otherwise use the provided value
      c = combo_levels[on_resource_type][can_perform] if valid_combo_level?(on_resource_type, can_perform)
      can_perform = c || can_perform

      conditions[:access] = can_perform
    end

    # Get the user's own access first, and the fallback of null last. If the
    # user does not have his own access, the default for the app type will return instead,
    # so that .first is always the most appropriate value
    self.active.where(conditions).order('user_id asc nulls last').first

  end


  # Create all possible controls on the specified app type
  def self.create_all_for app_type, admin, default_access=:create
    resource_names.each do |rn|
      rt = :table
      res = app_type.user_access_controls.build resource_name: rn, resource_type: rt, access: default_access, current_admin: admin, user_id: nil
      res.save! if app_type.persisted?
    end
  end

  # Add a new resource for all configured app types
  def self.create_control_for_all_apps admin, resource_type, resource_name, default_access: :create, disabled: nil

    AppType.active.all.each do |app_type|
      # Fails quietly if the item already exists
      UserAccessControl.create(user: nil, app_type: app_type, resource_type: resource_type, resource_name: resource_name, access: default_access, current_admin: admin)
    end
  end


  # Check which tables a user can view in the current app type, or an alternative app type if specified
  def self.view_tables? user, app_type, alt_app_type_id: nil
    view = {}
    resource_names.each do |r|
      view[r.to_sym] = !!access_for?(user, :access, :table, r, alt_app_type_id: alt_app_type_id)
    end

    view
  end

  private
    def correct_access
      self.access = nil if self.access.blank?
      if self.user && self.user.disabled != self.disabled
        errors.add :disabled, "flag of an access control must match the disabled flag for its user"
      elsif !self.class.valid_access_level?(:table, self.access)
        errors.add :access, "is an invalid value"
      elsif resource_type.nil? || !self.class.resource_types.include?(self.resource_type.to_sym)
        errors.add :resource_type, "is an invalid value"
      elsif resource_name.nil? || !self.class.resource_names.include?(self.resource_name.to_s)
        errors.add :resource_name, "is an invalid value"
      else
        res = self.class.access_for? self.user, nil, self.resource_type, self.resource_name, self.options, alt_app_type_id: self.app_type_id
        if res && res.id != self.id # If the user has the authorization set and it is not this record
          errors.add :user, "already has the access control #{self.access} on #{self.resource_type} #{self.resource_name} #{self.app_type.name} #{self.options}"
        end
      end

    end

end
