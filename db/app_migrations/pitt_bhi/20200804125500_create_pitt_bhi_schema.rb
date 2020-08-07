require 'active_record/migration/app_generator'
class CreatePittBhiSchema < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'pitt_bhi'
    self.owner = 'fphs'
    create_schema
  end
end
