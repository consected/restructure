require 'active_record/migration/app_generator'
class CreateEnvEnvironmentsQh0rvb < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'environments'
    self.table_name = 'env_environments'
    self.fields = %i[name description]
    self.table_comment = ''
    self.fields_comments = {}


    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
