# frozen_string_literal: true

class Admin::UserAccessControl < ActiveRecord::Base
  self.table_name = 'user_access_controls'

  include AdminHandler
  include AppTyped
  include UserAndRoles

  belongs_to :user, optional: true

  validate :correct_access
  after_save :invalidate_cache

  attr_accessor :allow_bad_resource_name

  def self.resource_types
    %i[table general limited_access report activity_log_type external_id_assignments]
  end

  # access levels provide a distinct scale of control for each resource type
  # for a specific named resource a user is only assigned a single access level
  # For example, on a table, a user is able to only read the table if he has :read, :update or :create
  # Another user may read or update the table if she has :update, or :create
  # A user may only create records on a table if she has :create

  def self.access_levels
    {
      table: [nil, :see_presence, :read, :update, :create],
      general: [nil, :read],
      limited_access: [nil, :limited],
      report: [nil, :read],
      activity_log_type: [nil, :see_presence, :read, :update, :create],
      external_id_assignments: [nil, :limited]
    }
  end

  def self.general_resource_names
    %w[
      app_type create_master
      export_csv export_json view_reports view_external_links edit_report_data create_report_data import_csv
      print
      download_files view_files_as_image view_files_as_html send_files_to_trash move_files user_file_actions
      view_dashboards
      view_data_reference
    ]
  end

  def self.valid_access_level?(on_resource_type, can_perform)
    can_perform = can_perform.to_sym if can_perform.respond_to? :to_sym
    res = access_levels[on_resource_type.to_sym]
    res&.include? can_perform
  end

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
      activity_log_type: {
        access: %i[read update create],
        see_presence_or_access: %i[see_presence read update create],
        edit: %i[update create]
      }
    }
  end

  def self.resource_names_for(resource_type)
    if resource_type == :table
      (Master.get_all_associations +
        ['item_flags'] +
        ActivityLog.active.map(&:resource_name) +
        DynamicModel.active.map(&:resource_name) +
        ExternalIdentifier.active.map(&:resource_name) +
        ItemFlag.active_resource_names
      ).uniq
    elsif resource_type == :general
      general_resource_names
    elsif resource_type == :external_id_assignments || resource_type == :limited_access
      ExternalIdentifier.active.map(&:resource_name) + DynamicModel.active.map(&:resource_name)
    elsif resource_type == :report
      Report.active.map(&:alt_resource_name) + Report.active.map(&:name) + ['_all_reports_']
    elsif resource_type == :activity_log_type
      ActivityLog.all_option_configs_resource_names
    else
      []
    end
  end

  def self.valid_combo_level?(on_resource_type, can_perform)
    return if can_perform.nil? || can_perform.is_a?(Array)

    res = combo_levels[on_resource_type.to_sym]
    can_perform = can_perform.to_sym if can_perform.respond_to? :to_sym
    res[can_perform] if res
  end

  def self.all_resource_names
    a = []
    resource_names = {}
    resource_types.each do |r|
      rn = resource_names[r]
      rn ||= resource_names[r] = resource_names_for(r)
      a += rn
    end
    a
  end

  def self.resource_names_by_type
    rn = {}
    resource_types.each do |k|
      rn[k] = resource_names_for(k).sort
    end
    rn
  end

  def self.options
    nil
  end

  # Find out if the user can perform a specific action on a named resource type in his current app type
  # Optionally provide can_perform=nil to find a record for any access level or
  # an array to check for multiple possible options
  # If it is necessary to check for access to a resource on an app type that is not the user's current one,
  # or the user is nil, specify the alt_app_type_id
  # Similarly, an alt_role_name can be specified
  #
  def self.access_for?(user, can_perform, on_resource_type, named, with_options = nil, alt_app_type_id: nil, alt_role_name: nil, add_conditions: nil)
    raise FphsException, 'Options can not be added to access_for?' if with_options

    app_type_id = alt_app_type_id || user&.app_type_id

    if can_perform
      unless can_perform.is_a?(Array) || valid_access_level?(on_resource_type, can_perform) || valid_combo_level?(on_resource_type, can_perform)
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

    res
  end

  # Create all possible controls on the specified app type
  # The default access is nil to avoid adding new resources to existing apps by accident
  def self.create_all_for(app_type, admin, default_access = nil)
    rt = :table
    resource_names_for(rt).each do |rn|
      res = app_type.user_access_controls.build resource_name: rn, resource_type: rt, access: default_access, current_admin: admin, user_id: nil
      res.save! if app_type.persisted?
    end
  end

  # Add a new resource for all configured app types
  # Make its default access nil to avoid exposing it to existing apps by accident
  def self.create_control_for_all_apps(admin, resource_type, resource_name, default_access: nil, disabled: nil)
    Admin::AppType.active.all.each do |app_type|
      # Fails quietly if the item already exists
      Admin::UserAccessControl.create(user: nil, app_type: app_type, resource_type: resource_type, resource_name: resource_name, access: default_access, current_admin: admin)
    end
  end

  def self.create_template_control(admin, app_type, resource_type, resource_name, default_access: :read, disabled: nil)
    # Fails quietly if the item already exists
    Admin::UserRole.create(role_name: Settings::AppTemplateRole, app_type: app_type, user: User.template_user, current_admin: admin)

    uac = Admin::UserAccessControl.where(role_name: Settings::AppTemplateRole, app_type: app_type, resource_type: resource_type, resource_name: resource_name).first

    if uac
      uac.update(role_name: Settings::AppTemplateRole, app_type: app_type, resource_type: resource_type, resource_name: resource_name, access: default_access, disabled: disabled, current_admin: admin)
    else
      Admin::UserAccessControl.create(role_name: Settings::AppTemplateRole, app_type: app_type, resource_type: resource_type, resource_name: resource_name, access: default_access, disabled: disabled, current_admin: admin)
    end
  end

  # Check which tables a user can view in the current app type, or an alternative app type if specified
  def self.view_tables?(user, alt_app_type_id: nil)
    view = {}
    resource_names_for(:table).each do |r|
      view[r.to_sym] = !!access_for?(user, :access, :table, r, alt_app_type_id: alt_app_type_id)
    end

    view
  end

  # Get list of controls for the external_id_assignments / limited_access type in the user's current app.
  # Get both the user's override, if it exists, and the default for each resource, which we then filter down to the actual access control
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

  def bad_resource_name(cache_resource_names_for_type = nil)
    return if disabled
    return true if resource_name.nil?

    resource_name_for_type = if cache_resource_names_for_type
                               cache_resource_names_for_type[resource_type.to_sym]
                             else
                               self.class.resource_names_for(resource_type.to_sym)
                             end

    !resource_name_for_type.include?(resource_name.to_s)
  end

  private

  def correct_access
    self.access = nil if access.blank?
    if disabled
      true
    elsif user&.disabled && !disabled
      errors.add :disabled, 'flag of an access control must be disabled, since the user is disabled'
    elsif !self.class.valid_access_level?(resource_type.to_sym, access)
      errors.add :access, 'is an invalid value'
    elsif resource_type.nil? || !self.class.resource_types.include?(resource_type.to_sym)
      errors.add :resource_type, 'is an invalid value'
    elsif !allow_bad_resource_name && (resource_name.nil? || !self.class.resource_names_for(resource_type.to_sym).include?(resource_name.to_s))
      errors.add :resource_name, "is an invalid value (#{resource_name} in #{resource_type})"
    elsif !disabled
      res = self.class.access_for? user, nil, resource_type, resource_name, alt_role_name: role_name, alt_app_type_id: app_type_id
      if res && res.id != id # If we have a result and it is not this record
        if user_id && user_id == res.user_id # If the user has the authorization set
          errors.add :user, "already has the access control #{access} on #{resource_type} #{resource_name} #{app_type ? app_type.name : ''} #{options}"
        elsif !user_id && res.user_id.nil? && role_name == res.role_name # If the new record has no user set and has a matching role _name
          errors.add :user_access_control, "already exists for #{role_name} #{access} on #{resource_type} #{resource_name} #{app_type ? app_type.name : ''} #{options}"
        end
      end
    end
  end

  def invalidate_cache
    logger.info "User Role added or updated (#{self.class.name}). Invalidating cache."
    # Unfortunately we have no way to clear pattern matched keys with memcached so we just clear the whole cache
    Rails.cache.clear
  end
end
