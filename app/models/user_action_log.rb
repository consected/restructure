class UserActionLog < ActiveRecord::Base
  # belongs_to :user
  # belongs_to :app_type
  # belongs_to :master

  validates :master_id, presence: true, unless: -> {item_type == 'masters'}
  validates :user_id, presence: true
  validates :app_type_id, presence: true
end
