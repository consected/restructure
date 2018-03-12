class AppConfiguration < ActiveRecord::Base
  include AdminHandler
  include SelectorCache
  include AppTyped

  belongs_to :user
  validates :name, presence: true

  def self.configurations
    [
      "create master with",
      "default search form", "hide master id in results", "hide navbar search", "hide player accuracy",
      "hide player tabs", "hide pro info", "hide search form advanced", "hide search form searchable reports",
      "hide search form simple", "hide tracker panel", "menu create master record label",
      "menu research label", "notes field caption", "show activity log panel", "user session timeout"
    ]
  end
  # Use `Configuration.value_for name` to get a cached configuration value

  # Allow the use of symbols to retrieve entries
  # If a user is set, use it to override the default value
  # Otherwise just return the default value if no user is set
  # user attribute can be a User or an id
  def self.value_for name, user=nil
    if name.is_a? Symbol
      name = name.to_s.humanize.downcase
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

end
