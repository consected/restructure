require 'active_record/migration/app_generator'
class CreateEnvironmentsSchemaQh06t2 < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'environments'
    self.owner = 'fphs'
    create_schema
  end
end
