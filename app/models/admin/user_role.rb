class Admin::UserRole < ActiveRecord::Base

  self.table_name = 'user_roles'

  include AdminHandler
  include AppTyped

  belongs_to :user

  validates :role_name, presence: true
  validates :user_id, uniqueness: {scope: [:app_type_id, :role_name]}

  # Scope used when user.user_roles association is called, effectively forcing the results
  # to the user's current app type
  scope :user_app_type, ->(user) { where user_roles: { app_type_id: user.app_type_id } }


  # Get a resultset of active roles for the user.
  # @param user [User] if the app_type attribute is set in the user, and is not set in conditions
  #                    then the user app_type will be used
  # @param conditions [Hash] if app_type or app_type_id are set then they will be used to set the app_type,
  #                          overriding the attribute set in the user
  # @return [ActiveRecord::Relation]
  def self.active_app_roles user, conditions={}
    app_type = conditions[:app_type] || conditions[:app_type_id] || user.app_type
    active.where user: user, app_type: app_type
  end

  # Prevent Admin::UserRole.where from accidentally bypassing the app_type scoping.
  # @param conditions [Hash] full set of where clause conditions
  # @return [ActiveRecord::Relation]
  def self.where conditions
    if conditions.is_a?(Hash) && conditions.length > 0
      ur_cond = conditions.dup
      ur_cond = conditions[:user_roles] if conditions[:user_roles]
      ur_cond = ur_cond.symbolize_keys
      raise FphsException.new "UserRole.where must use app_type condition" unless ur_cond[:id] || ur_cond[:app_type] || ur_cond[:app_type_id]
    end
    super
  end

  # Get role names from, either unfiltered, or from a previous scope
  # @return [Array] list of string role names
  def self.role_names
    select("role_name").distinct.pluck(:role_name)
  end

  # Get roles names in a hash, keyed by the app name. May be filtered by a previous scope
  # @return [Hash] hash with string keys of app names and values as arrays of role names for each
  def self.role_names_by_app_name
    res = all
    items = {}
    res.each do |role|
      n = role.app_type_id
      items[n] ||= []
      items[n] << role.role_name unless items[n].include? role.role_name
    end
    items
  end

  def self.users
    user_ids = select("user_id").distinct.pluck(:user_id)
    User.where id: user_ids
  end

  # conditions must include app_type and role_name, and may include other conditions
  def self.active_user_ids conditions=nil, app_type:, role_name:
    res = select("user_id").joins(:user).where(
      "(user_roles.disabled is null or user_roles.disabled = false) AND (users.disabled is null or users.disabled = false)"
    )
    res = res.where app_type: app_type, role_name: role_name
    res = res.where conditions if conditions

    res.distinct.pluck(:user_id)
  end

  def self.find_user_role_for_user user, app_type, role_name
    user.user_roles.where(app_type: app_type, role_name: role_name).first
  end

  def self.add_to_role user, app_type, role_name, admin
    res = find_user_role_for_user user, app_type, role_name
    if res
      res.with_admin(admin).enable! if res.disabled?
    else
      user.user_roles.create!(app_type: app_type, role_name: role_name, disabled: false, current_admin: admin)
    end
  end

  def self.remove_from_role user, app_type, role_name, admin
    res = find_user_role_for_user user, app_type, role_name
    res.with_admin(admin).disable! if res
  end

end
