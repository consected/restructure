require 'active_record/migration/app_generator'
class UpdateDataRequestsSelectedAttribsQec1p2 < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'data_requests'
    self.table_name = 'data_requests_selected_attribs'
    self.fields = %i[record_id data data_request_id disabled variable_name record_type]
    self.table_comment = ''
    self.fields_comments = {}


    # added: ["record_type"]
    # removed: []
    
    
    update_fields

    create_dynamic_model_trigger
  end
end
