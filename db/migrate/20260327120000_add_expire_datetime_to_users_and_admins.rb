# frozen_string_literal: true

class AddExpireDatetimeToUsersAndAdmins < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :expire_datetime, :datetime, null: true
    add_column :admins, :expire_datetime, :datetime, null: true
  end
end
