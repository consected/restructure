require 'active_record/migration/app_generator'
class CreateEnvHostingAccountsQh0ry8 < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'environments'
    self.table_name = 'env_hosting_accounts'
    self.fields = %i[name provider account_number login_url primary_admin description]
    self.table_comment = ''
    self.fields_comments = {}


    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
