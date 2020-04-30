class Admin::AppConfiguration < Admin::AdminBase

  self.table_name = 'app_configurations'

  include AdminHandler
  include SelectorCache
  include AppTyped
  include UserAndRoles

  belongs_to :user, optional: true
  before_validation :humanize_name
  validates :name, presence: true
  validate :valid_entry

  # Special notes:
  # hide and show items should enter true, false or blank (equivalent to false)
  # menu research label may enter none to hide the menu (otherwise it defaults to Research)


  def self.configurations
    [
      "create master with", "completion sub processes",
      "default search form", "default report tab", "file browser default view", "header no subject details label", "header subject data type", "hide navbar search", "hide player accuracy",
      "hide player tabs", "hide pro info", "hide search form advanced", "hide search form searchable reports",
      "hide search form simple", "hide tracker panel", "heading create master record label", "filestore directory id",
      "master header prefix", "menu create master record label",
      "menu research label", "notes field caption", "notes field format", "open panels", "show activity log panel", "show ids in master result", "user session timeout"
    ]
  end

  # Use `Admin::AppConfiguration.value_for name` to get a cached configuration value
  # Allows the use of symbols to retrieve entries
  # If a user is set, use it to override the default value with either the username or role names
  # Otherwise just return the default value if no user is set
  # user attribute can be a User or an id
  def self.value_for name, user=nil
    if name.is_a? Symbol
      name = sym_to_name(name)
    end
    res = where(name: name)
    res.scope_user_and_role(user).first&.value
  end

  # Get an array of comma separated values from an app config value
  def self.values_for name, user=nil, to: :to_sym
    res = value_for(name, user)
    res = '' if res.blank?
    res.split(',').map {|i| i.strip.send(to)}
  end

  def self.all_for user=nil
    names = active.pluck(:name)
    results = {}
    names.each do |name|
      name_sym = name.id_underscore.to_sym
      results[name_sym] = value_for(name, user)
    end
    results
  end

  def self.sym_to_name config_name
    config_name.to_s.humanize.downcase
  end


  def self.find_app_config_for_user user, app_type, config_name
    Admin::AppConfiguration.where(app_type: app_type, user: user, name: sym_to_name(config_name)).first
  end

  def self.find_default_app_config app_type, config_name
    Admin::AppConfiguration.where(app_type: app_type, name: sym_to_name(config_name)).first
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

        cond = {name: self.name, user: self.user, role_name: self.role_name, app_type: self.app_type}
        res = self.class.active.where(cond).first
        raise FphsException.new "Invalid configuration name: #{self.name}" unless self.name.in? self.class.configurations
        raise FphsException.new "This item already exists (#{self.name} user: #{self.user_id} role_name: #{self.role_name} app_type: #{self.app_type_id})" if res && ((persisted? && res.id != self.id) || !persisted?)

      end
    end


end
