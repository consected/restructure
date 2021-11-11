require 'active_record/migration/app_generator'
class CreateRedcapTestSchemaQoezsq < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'redcap_test'

    create_schema
  end
end
