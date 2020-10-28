class AddUserIdToAppConfigurations < ActiveRecord::Migration
  def change
    add_reference :app_configurations, :user, index: true, foreign_key: true
  end
end
