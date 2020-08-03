require 'active_record/migration/app_generator'
class UpdateDataRequestsSelectedAttribsQebzkb < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'data_requests'
    self.table_name = 'data_requests_selected_attribs'
    self.fields = %i[record_id data data_request_id disabled variable_name]
    self.table_comment = ''
    self.fields_comments = {}


    # added: []
    # removed: ["record_type"]
    
    
    update_fields

    create_dynamic_model_trigger
  end
end
