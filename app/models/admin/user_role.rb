# frozen_string_literal: true

class Admin::UserRole < ActiveRecord::Base
  self.table_name = 'user_roles'

  include AdminHandler
  include AppTyped

  belongs_to :user, optional: true

  validates :role_name, presence: true
  validates :user_id, uniqueness: { scope: %i[app_type_id role_name disabled] }, unless: lambda {
                                                                                           user_id.nil? || disabled?
                                                                                         }

  after_save :save_template
  after_save :invalidate_cache

  # Scope used when user.user_roles association is called, effectively forcing the results
  # to the user's current app type
  scope :user_app_type, ->(user) { where user_roles: { app_type_id: user.app_type_id } }

  # Get a resultset of active roles for the user.
  # @param user [User] if the app_type attribute is set in the user, and is not set in conditions
  #                    then the user app_type will be used
  # @param conditions [Hash] if app_type or app_type_id are set then they will be used to set the app_type,
  #                          overriding the attribute set in the user
  # @return [ActiveRecord::Relation]
  def self.active_app_roles(user, conditions = {})
    app_type = conditions[:app_type] || conditions[:app_type_id] || user.app_type
    active.where user: user, app_type: app_type
  end

  # Prevent Admin::UserRole.where from accidentally bypassing the app_type scoping.
  # @param conditions [Hash] full set of where clause conditions
  # @return [ActiveRecord::Relation]
  def self.where(conditions)
    if conditions.is_a?(Hash) && !conditions.empty?
      ur_cond = conditions.dup
      ur_cond = conditions[:user_roles] if conditions[:user_roles]
      ur_cond = ur_cond.symbolize_keys
      unless ur_cond[:id] || ur_cond[:app_type] || ur_cond[:app_type_id]
        raise FphsException, 'UserRole.where must use app_type condition'
      end
    end
    super
  end

  # Get role names from, either unfiltered, or from a previous scope
  # @return [Array] list of string role names
  def self.role_names
    select('role_name').distinct.pluck(:role_name)
  end

  def self.active_role_names(filter = nil)
    q = active
    q = q.where(filter) if filter
    q.role_names
  end

  # Get roles names in a hash, keyed by the "app.id/app.name". May be filtered by a previous scope
  # @return [Hash] hash with string keys of app names and values as arrays of role names for each
  def self.role_names_by_app_name
    res = all.order(role_name: :asc)
    items = {}
    res.each do |role|
      m = role.app_type
      n = "#{m.id}/#{m.name}"
      items[n] ||= []
      items[n] << role.role_name unless items[n].include? role.role_name
    end
    items
  end

  def self.users
    user_ids = select('user_id').distinct.pluck(:user_id)
    User.where id: user_ids
  end

  # conditions must include app_type and role_name, and may include other conditions
  def self.active_user_ids(conditions = nil, app_type:, role_name:)
    condsql = '(user_roles.disabled is null or user_roles.disabled = false) AND '\
              '(users.disabled is null or users.disabled = false)'
    res = select('user_id').joins(:user).where(condsql)

    res = res.where app_type: app_type, role_name: role_name
    res = res.where conditions if conditions

    res.distinct.pluck(:user_id)
  end

  def self.find_user_role_for_user(user, app_type, role_name)
    user.user_roles.where(app_type: app_type, role_name: role_name).first
  end

  def self.add_to_role(user, app_type, role_name, admin)
    res = find_user_role_for_user user, app_type, role_name
    if res
      res.with_admin(admin).enable! if res.disabled?
    else
      user.user_roles.create!(app_type: app_type, role_name: role_name, disabled: false, current_admin: admin)
    end
  end

  def self.remove_from_role(user, app_type, role_name, admin)
    res = find_user_role_for_user user, app_type, role_name
    res&.with_admin(admin)&.disable!
  end

  # Copy roles from one user to another. To avoid confusion, app_type must be specified
  # @param from_user [User] user to copy roles from
  # @param to_user [User] user to copy roles to
  # @param app_type [Admin::AppType] the app type the roles belong to.
  # @return [Array] array of Admin::UserRole instances created in the to_user
  def self.copy_user_roles(from_user, to_user, app_type, current_admin)
    raise FphsException, 'app_type must be specified and not nil to copy roles' unless app_type

    has_roles = Admin::UserRole.active_app_roles to_user, app_type: app_type
    raise FphsException, "can not copy roles to a user with roles in this app #{app_type}" unless has_roles.empty?

    from_roles = Admin::UserRole.active_app_roles from_user, app_type: app_type

    to_roles = []
    from_roles.each do |r|
      new_role = {
        current_admin: current_admin,
        role_name: r.role_name,
        app_type: app_type,
        user: to_user
      }
      to_roles << create!(new_role)
    end

    to_roles
  end

  def self.latest_update
    return @latest_update if @latest_update

    obj = reorder('').order(Arel.sql('coalesce(updated_at, created_at) desc nulls last')).first
    @latest_update = obj&.updated_at || obj&.created_at
  end

  def self.reset_latest_update
    @latest_update = nil
  end

  private

  # Automatically add a template@template record if needed
  def save_template
    return true if disabled?

    tu = User.template_user
    tu.app_type = app_type
    self.class.add_to_role tu, app_type, role_name, current_admin
  end

  def invalidate_cache
    logger.info "User Role added or updated (#{self.class.name}). Invalidating cache."
    self.class.reset_latest_update

    # Unfortunately we have no way to clear pattern matched keys with memcached so we just clear the whole cache
    Rails.cache.clear
  end
end
