require 'active_record/migration/app_generator'
class CreateRcSampleResponsesQoezsq < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'test'
    self.table_name = 'rc_sample_responses'
    self.fields = %i[record_id dob current_weight smoketime___pnfl smoketime___dnfl smoketime___anfl smoke_start
                     smoke_stop smoke_curr demog_date ncmedrec_add ladder_wealth ladder_comm born_address twelveyrs_address othealth___complete othealth_date q2_survey_complete
                     sdfsdaf___0 sdfsdaf___1 sdfsdaf___2 rtyrtyrt___0 rtyrtyrt___1 rtyrtyrt___2 test_field test_phone i57 f57 dd yes_or_no test_complete disabled]
    self.table_comment = 'Dynamicmodel: Rc Sample Response'
    self.fields_comments = {}
    self.db_configs = {
      record_id: { type: :string },
      dob: { type: :date },
      current_weight: { type: :decimal },
      smoketime___pnfl: { type: :boolean },
      smoketime___dnfl: { type: :boolean },
      smoketime___anfl: { type: :boolean },
      smoke_start: { type: :decimal },
      smoke_stop: { type: :decimal },
      smoke_curr: { type: :string },
      demog_date: { type: :timestamp },
      ncmedrec_add: { type: :string },
      ladder_wealth: { type: :string },
      ladder_comm: { type: :string },
      born_address: { type: :string },
      twelveyrs_address: { type: :string },
      othealth___complete: { type: :boolean },
      othealth_date: { type: :timestamp },
      q2_survey_complete: { type: :integer },
      sdfsdaf___0: { type: :boolean },
      sdfsdaf___1: { type: :boolean },
      sdfsdaf___2: { type: :boolean },
      rtyrtyrt___0: { type: :boolean },
      rtyrtyrt___1: { type: :boolean },
      rtyrtyrt___2: { type: :boolean },
      test_field: { type: :string },
      test_phone: { type: :string },
      i57: { type: :integer },
      f57: { type: :decimal },
      dd: { type: :timestamp },
      yes_or_no: { type: :boolean },
      test_complete: { type: :integer }

    }
    self.no_master_association = true

    create_schema
    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
