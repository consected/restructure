require 'active_record/migration/app_generator'
class UpdateDataRequestsQh5u1i < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'data_requests'
    self.table_name = 'data_requests'
    self.fields = %i[status project_title select_purpose other_purpose research_question_notes fphs_analyst_yes_no full_name title institution other_institution others_handling_data pm_contact other_pm_contact data_start_date data_end_date fphs_server_yes_no fphs_server_tools_notes off_fphs_server_reason_notes data_use_agreement_status data_use_agreement_notes terms_of_use_yes_no created_by_user_id]
    self.table_comment = ''
    self.fields_comments = {}
    self.no_master_association = false

    self.prev_fields = %i[project_title concept_sheet_approved_yes_no concept_sheet_approved_by full_name title institution other_institution others_handling_data pm_contact other_pm_contact data_use_agreement_status data_use_agreement_notes terms_of_use_yes_no data_start_date data_end_date fphs_analyst_yes_no fphs_server_yes_no fphs_server_tools_notes off_fphs_server_reason_notes status created_by_user_id]
    # added: ["select_purpose", "other_purpose", "research_question_notes"]
    # removed: ["concept_sheet_approved_yes_no", "concept_sheet_approved_by"]

    update_fields

    create_dynamic_model_trigger
  end
end
