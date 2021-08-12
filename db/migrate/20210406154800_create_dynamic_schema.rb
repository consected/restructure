require 'active_record/migration/app_generator'
class CreateDynamicSchema < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'dynamic'
    self.owner = 'restradmin'
    create_schema
  end
end
