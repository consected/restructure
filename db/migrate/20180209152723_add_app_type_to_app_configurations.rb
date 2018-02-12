class AddAppTypeToAppConfigurations < ActiveRecord::Migration
  def change
    add_reference :app_configurations, :app_type, index: true, foreign_key: true
  end
end
