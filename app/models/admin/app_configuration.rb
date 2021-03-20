# frozen_string_literal: true

# App Configurations provide the administrator the opportunity to set some common
# labels, links and functionality within an app type.
# The configurations have an override precendence, so that the same configuration item
# for the app can be overridden by a specified role, and that can be overriden
# by a specified user.
# Configurations are named and saved in the database as show
# in Admin::AppConfiguration.configurations but can be referenced without spaces as
# symbols when retrieving.
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
  after_save :clear_memo!

  # Special notes:
  # hide and show items should enter true, false or blank (equivalent to false)
  # menu research label may enter none to hide the menu (otherwise it defaults to Research)

  def self.configurations
    configuation_meanings.keys
  end

  def self.configuation_meanings
    {
      'create master with' => 'Form to embed in the "create master" block. A dynamic data model or participant resource name.',
      'heading create master record label' => 'Heading appearing on the "create master" block. Default is "Create a new Master Record"',
      'menu create master record label' => 'In the main menu navbar, what ',
      'completion sub processes' => 'Completion events to be displayed as badges on the Tracker panel. A commma separate list of subprocess IDs',
      'default search form' => 'Search form to display by default. A report resource name',
      'default report tab' => 'The default report category (tab) to display when listing reports. A report category',
      'file browser default view' => 'Initial view on a filestore brower. One of "no details", "file info", "classifications"',
      'header no subject details label' => 'Text to display in a master record header if no participant details are available. By default "(no subject details)". Will be presented as blank if the value is "none"',
      'header subject data type' => 'In the master header, the data model to get subject names from. A data model resource name',
      'header secondary data type' => 'In the master header, the data model to get secondary subject names from. A data model resource name',
      'hide navbar search' => 'By default, the main menu navbar has ID search fields. Value "true" hides it',
      'hide player accuracy' => 'Hide the primary participant accuracy in master header and on the details block. Value "true" hides it',
      'hide participant accuracy' => 'Hide the primary participant accuracy in master header and on the details block. Value "true" hides it',
      'hide player tabs' => 'In a master record, the tabs row pointing to panels can be hidden. Value "true" hides it',
      'hide participant tabs' => 'In a master record, the tabs row pointing to panels can be hidden. Value "true" hides it',
      'hide pro info' => 'Hide the secondary participant info block and master header summary. Value "true" hides it',
      'hide secondary info' => 'Hide the secondary participant info block and master header summary. Value "true" hides it',
      'hide search form advanced' => 'Hide the "advanced" search form. Value "true" hides it',
      'hide search form simple' => 'Hide the "simple" search form. Value "true" hides it',
      'hide search form searchable reports' => 'Don\'t show reports marked as "searchable" as search forms. Value "true" hides them',
      'hide tracker panel' => 'The Tracker panel in a master record can be hidden. Value "true" hides it',
      'filestore directory id' => 'If the server setting for use_parent_sub_dir is set, this value is the external ID resource name to getthe identifier from. By default it uses master ID',
      'logo filename' => 'Use an alternative logo. Path relative to the app root for a logo. For example: /app_specific/sample_app/project-logo.png',
      'logo link' => 'Link to go to when the logo is clicked. By default "/". Relative to the app root',
      'master header prefix' => 'Prefix to display on the master header. May include curly {{ substitutions }}',
      'master header title' => 'Alternative text  appear instead of participant info names on the master header. May include curly {{ substitutions }}',
      'menu research label' => '',
      'notes field caption' => '',
      'notes field format' => '',
      'open panels' => '',
      'prevent reload master list' => '',
      'reports list title' => '',
      'report library button label' => '',
      'show activity log panel' => '',
      'show ids in master result' => '',
      'show search form on single result' => '',
      'user session timeout' => ''
    }
  end

  # Use `Admin::AppConfiguration.value_for name` to get a cached configuration value
  # Allows the use of symbols to retrieve entries
  # If a user is set, use it to override the default value with either the username or role names
  # Otherwise just return the default value if no user is set
  # user attribute can be a User or an id
  #
  # This memoizes in the class, to avoid repetitive DB calls, so requires a #clear_memo! after config changes.
  def self.value_for(name, user = nil)
    name = sym_to_name(name)

    @value_for ||= {}
    key = value_for_memo_key(name, user)

    return @value_for[key] if @value_for.key?(key)

    @value_for[key] =
      where(name: name).scope_user_and_role(user).first&.value
  end

  #
  # Get an array of comma separated values from an app config value
  def self.values_for(name, user = nil, to: :to_sym)
    res = value_for(name, user)
    res = '' if res.blank?
    res.split(',').map { |i| i.strip.send(to) }
  end

  #
  # Get all the active config values for the specified user.
  # The user's current app type is considered in the evaluation
  # when #value_for is called to get the value for each name
  # as a hash keyed by the name
  def self.all_for(user = nil)
    names = active.pluck(:name)
    results = {}
    names.each do |name|
      name_sym = name.id_underscore.to_sym
      results[name_sym] = value_for(name, user)
    end
    results
  end

  #
  # Find the app config within the app type, for the specified user, by name.
  # If the config_name is a Symbol it will be converted
  # to a usable space-separated name. If a String is supplied, it must already
  # be space separated.
  # @param [Admin::AppType | Integer] app_type
  # @param [User] user
  # @param [Symbol | String] config_name
  # @return [Admin::AppConfiguration] first matching instance
  def self.find_app_config_for_user(user, app_type, config_name)
    Admin::AppConfiguration.where(app_type: app_type, user: user, name: sym_to_name(config_name)).first
  end

  #
  # Find the default config (no user or role specified in the configuration)
  # within the app type, by name.
  # If the config_name is a Symbol it will be converted
  # to a usable space-separated name. If a String is supplied, it must already
  # be space separated.
  # @param [Admin::AppType | Integer] app_type
  # @param [Symbol | String] config_name
  # @return [Admin::AppConfiguration] first matching instance
  def self.find_default_app_config(app_type, config_name)
    Admin::AppConfiguration.where(
      app_type: app_type,
      name: sym_to_name(config_name),
      user_id: nil,
      role_name: nil
    ).first
  end

  #
  # Add a default config (no user or role specified in the configuration)
  # @return [Admin::AppConfiguration] instance updated or created
  def self.add_default_config(app_type, config_name, config_value, admin)
    config_name = sym_to_name(config_name)
    res = find_default_app_config(app_type, config_name)
    if res
      res.update!(value: config_value, disabled: false, current_admin: admin)
    else
      res = create!(app_type: app_type, user: nil, name: config_name, value: config_value, current_admin: admin)
    end
    res
  end

  #
  # If a default config is available (no user specified in the configuration)
  # remove it
  def self.remove_default_config(app_type, config_name, admin)
    config_name = sym_to_name(config_name)
    res = find_default_app_config(app_type, config_name)

    res&.with_admin(admin)&.disable!
  end

  #
  # Add a config with a value, tied to a user
  # @return [Admin::AppConfiguration] instance updated or created
  def self.add_user_config(user, app_type, config_name, config_value, admin)
    config_name = sym_to_name(config_name)
    res = find_app_config_for_user(user, app_type, config_name)
    if res
      res.update!(value: config_value, disabled: false, current_admin: admin)
    else
      res = create!(app_type: app_type, user: user, name: config_name, value: config_value, current_admin: admin)
    end
    res
  end

  #
  # If a config is specified that is tied to a user, remove it
  def self.remove_user_config(user, app_type, config_name, admin)
    config_name = sym_to_name(config_name)
    res = find_app_config_for_user(user, app_type, config_name)

    res&.with_admin(admin)&.disable!
  end

  #
  # Convert an underscored symbol config name into
  # a space separated string
  # If a non-symbol is passed in, the original value is returned unchanged
  def self.sym_to_name(config_name)
    return config_name unless config_name.is_a? Symbol

    config_name.to_s.humanize.downcase
  end

  #
  # A memoization key for value_for cache
  # Memoization is keyed as "#{current_user.id}-#{current_user.app_type_id}-#{item}" to ensure a
  # user app type change is appropriately recognized
  # @param [Symbol] name
  # @param [User] user
  # @return [String]
  def self.value_for_memo_key(name, user)
    "#{user&.id}-#{user&.app_type_id}-#{name}"
  end

  #
  # Clear the value_for memo. Called as an after_save callback
  def self.clear_memo!
    @value_for = {}
  end

  private

  def humanize_name
    self.name = self.class.sym_to_name(name) if name.present?
  end

  #
  # Validation of the name, role and user to check for existence
  def valid_entry
    return if disabled

    cond = { name: name, user: user, role_name: role_name, app_type: app_type }
    res = self.class.active.where(cond).first
    raise FphsException, "Invalid configuration name: #{name}" unless name.in? self.class.configurations

    return unless res && ((persisted? && res.id != id) || !persisted?)

    raise FphsException,
          "This item already exists (#{name} user: #{user_id} role_name: #{role_name} app_type: #{app_type_id})"
  end

  #
  # Clear the value_for memo.
  def clear_memo!
    self.class.clear_memo!
  end
end
