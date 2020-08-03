require 'active_record/migration/app_generator'
class UpdateDataRequestsQec0nf < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'data_requests'
    self.table_name = 'data_requests'
    self.fields = %i[status project_title fphs_analyst_yes_no full_name title institution other_institution others_handling_data pm_contact other_pm_contact data_start_date data_end_date fphs_server_yes_no fphs_server_tools_notes off_fphs_server_reason_notes data_use_agreement_status data_use_agreement_notes terms_of_use_yes_no created_by_user_id]
    self.table_comment = ''
    self.fields_comments = {}


    # added: []
    # removed: ["concept_sheet_approved_yes_no", "concept_sheet_approved_by"]
    
    
    update_fields

    create_dynamic_model_trigger
  end
end
