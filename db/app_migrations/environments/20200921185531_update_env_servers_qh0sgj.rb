require 'active_record/migration/app_generator'
class UpdateEnvServersQh0sgj < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'environments'
    self.table_name = 'env_servers'
    self.fields = %i[name server_type hosting_account_id hosting_category server_hosting_name server_primary_admin description]
    self.table_comment = ''
    self.fields_comments = {}


    self.prev_fields = %i[environment_name name server_type hosting_account_name hosting_category server_hosting_name server_primary_admin description]
    # added: ["hosting_account_id"]
    # removed: ["environment_name", "hosting_account_name"]
    
    
    update_fields

    create_dynamic_model_trigger
  end
end
