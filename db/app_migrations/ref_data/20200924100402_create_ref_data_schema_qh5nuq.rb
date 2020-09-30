require 'active_record/migration/app_generator'
class CreateRefDataSchemaQh5nuq < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'ref_data'
    self.owner = 'fphs'
    create_schema
  end
end
