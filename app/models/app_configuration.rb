class AppConfiguration < ActiveRecord::Base
  include AdminHandler
  include SelectorCache
  include AppTyped

  belongs_to :user
  validates :name, presence: true
  validate :valid_entry

  # Special notes:
  # hide and show items should enter true, false or blank (equivalent to false)
  # menu research label may enter none to hide the menu (otherwise it defaults to Research)


  def self.configurations
    [
      "create master with",
      "default search form", "hide navbar search", "hide player accuracy",
      "hide player tabs", "hide pro info", "hide search form advanced", "hide search form searchable reports",
      "hide search form simple", "hide tracker panel", "heading create master record label", "menu create master record label",
      "menu research label", "notes field caption", "show activity log panel", "show ids in master result", "user session timeout"
    ]
  end
  # Use `AppConfiguration.value_for name` to get a cached configuration value

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


  private

    def valid_entry
      unless self.disabled

        cond = {name: self.name, user: self.user, app_type: self.app_type}
        res = self.class.active.where(cond).first

        raise FphsException.new "This item already exists (#{self.name} user: #{self.user_id} app_type: #{self.app_type_id})" if res && ((persisted? && res.id != self.id) || !persisted?)

      end
    end


end
