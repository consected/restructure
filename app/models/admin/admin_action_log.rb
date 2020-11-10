class Admin::AdminActionLog < ActiveRecord::Base

  self.table_name = 'admin_action_logs'

  validates :admin_id, presence: true
  validates :prev_value, presence: true, unless: -> {action == 'create'}
  validates :new_value, presence: true
  validates :item_id, presence: true
  validates :item_type, presence: true
  validates :action, presence: true
  validates :url, presence: true
end
