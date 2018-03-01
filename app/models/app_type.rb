class AppType < ActiveRecord::Base
  include AdminHandler
  include SelectorCache

  has_many :user_access_controls, autosave: true
  has_many :app_configurations, autosave: true

  validates :name, presence: true
  validates :label, presence: true, uniqueness: true
  after_save :set_access_levels

  def self.all_available_to user
    atavail = []

    self.active.each do |a|
      hat = user.has_access_to?(:access, :general, :app_type, alt_app_type_id: a.id)
      atavail << hat.app_type if hat
    end
    atavail
  end

  def self.all_by_name
    res = {}

    self.active.each do |a|
      res[a.id.to_s] = a.name.underscore
    end

    res
  end

  private

    def set_access_levels
      if !persisted? || self.user_access_controls.length == 0
        UserAccessControl.create_all_for self, current_admin
        return true
      end
    end

end
