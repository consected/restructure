require 'active_record/migration/app_generator'
class CreateEnvServersQh0ry2 < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'environments'
    self.table_name = 'env_servers'
    self.fields = %i[environment_name name server_type hosting_account_name hosting_category server_hosting_name server_primary_admin description]
    self.table_comment = ''
    self.fields_comments = {}


    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
