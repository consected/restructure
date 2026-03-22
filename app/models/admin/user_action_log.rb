# frozen_string_literal: true

class Admin::UserActionLog < ActiveRecord::Base
  self.table_name = 'user_action_logs'

  attr_accessor :no_master_association

  # validates :master_id, presence: true, unless: -> { item_type == 'masters' || item_type == 'reports' || no_master_association }
  validates :user_id, presence: true
  validates :app_type_id, presence: true
end
