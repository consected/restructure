class Admin::AppConfiguration < Admin::AdminBase

  self.table_name = 'app_configurations'

  include AdminHandler
  include SelectorCache
  include AppTyped

  belongs_to :user
  before_validation :humanize_name
  validates :name, presence: true
  validate :valid_entry

  # Special notes:
  # hide and show items should enter true, false or blank (equivalent to false)
  # menu research label may enter none to hide the menu (otherwise it defaults to Research)


  def self.configurations
    [
      "create master with",
      "default search form", "default report tab", "hide navbar search", "hide player accuracy",
      "hide player tabs", "hide pro info", "hide search form advanced", "hide search form searchable reports",
      "hide search form simple", "hide tracker panel", "heading create master record label", "menu create master record label",
      "menu research label", "notes field caption", "show activity log panel", "show ids in master result", "user session timeout"
    ]
  end
  # Use `Admin::AppConfiguration.value_for name` to get a cached configuration value

  # Allow the use of symbols to retrieve entries
  # If a user is set, use it to override the default value
  # Otherwise just return the default value if no user is set
  # user attribute can be a User or an id
  def self.value_for name, user=nil
    if name.is_a? Symbol
      name = sym_to_name(name)
    end

    app_type_id = user.app_type_id if user

    res = user_value_for(name, app_type_id: app_type_id)

    if user.nil?
      user_id = nil
    elsif user.is_a? User
      user_id = user.id
    else
      user_id = user
    end

    res_user = user_value_for(name, user_id: user_id, app_type_id: app_type_id) if user_id

    # since results are returned as nil if there was no entry and blank if there was (but it was not set)
    # we can return with a override expression

    res_user || res

  end

  def self.sym_to_name config_name
    config_name.to_s.humanize.downcase
  end


  def self.find_app_config_for_user user, app_type, config_name
    Admin::AppConfiguration.where(app_type: app_type, user: user, name: sym_to_name(config_name)).first
  end

  def self.find_default_app_config app_type, config_name
    res = Admin::AppConfiguration.where(app_type: app_type, name: sym_to_name(config_name)).first
  end

  def self.add_default_config app_type, config_name, config_value, admin
    config_name = sym_to_name(config_name)
    res = find_default_app_config(app_type, config_name)
    if res
      res.update!(value: config_value, disabled: false, current_admin: admin)
    else
      self.create!(app_type: app_type, user: nil, name: config_name, value: config_value, current_admin: admin)
    end
  end

  def self.remove_default_config app_type, config_name, admin
    config_name = sym_to_name(config_name)
    res = find_default_app_config(app_type, config_name)

    res.with_admin(admin).disable! if res
  end

  def self.add_user_config user, app_type, config_name, config_value, admin
    config_name = sym_to_name(config_name)
    res = self.find_app_config_for_user(user, app_type, config_name)
    if res
      res.update!(value: config_value, disabled: false, current_admin: admin)
    else
      self.create!(app_type: app_type, user: user, name: config_name, value: config_value, current_admin: admin)
    end
  end

  def self.remove_user_config user, app_type, config_name, admin
    config_name = sym_to_name(config_name)
    res = self.find_app_config_for_user(user, app_type, config_name)

    res.with_admin(admin).disable! if res
  end


  private

    def humanize_name
      if self.name.present?
        self.name = self.class.sym_to_name(self.name)
      end
    end

    def valid_entry
      unless self.disabled

        cond = {name: self.name, user: self.user, app_type: self.app_type}
        res = self.class.active.where(cond).first
        raise FphsException.new "Invalid configuration name: #{self.name}" unless self.name.in? self.class.configurations
        raise FphsException.new "This item already exists (#{self.name} user: #{self.user_id} app_type: #{self.app_type_id})" if res && ((persisted? && res.id != self.id) || !persisted?)

      end
    end


end
