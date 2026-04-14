# frozen_string_literal: true

class AddApiAccessOnlyToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :api_access_only, :boolean, default: false
  end
end
