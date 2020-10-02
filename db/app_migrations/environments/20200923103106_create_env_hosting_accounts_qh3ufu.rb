require 'active_record/migration/app_generator'
class CreateEnvHostingAccountsQh3ufu < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'environments'
    self.table_name = 'env_hosting_accounts'
    self.fields = %i[name provider account_number login_url primary_admin description created_by_user_id]
    self.table_comment = ''
    self.fields_comments = {}
    self.no_master_association = true


    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
