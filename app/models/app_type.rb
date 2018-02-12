class AppType < ActiveRecord::Base
  include AdminHandler
  include SelectorCache

  has_many :user_access_controls, autosave: true
  has_many :app_configurations, autosave: true

  validates :name, presence: true
  validates :label, presence: true, uniqueness: true
  after_save :set_access_levels


  private

    def set_access_levels
      if !persisted? || self.user_access_controls.length == 0
        UserAccessControl.create_all_for self, current_admin
        return true
      end
    end

end
