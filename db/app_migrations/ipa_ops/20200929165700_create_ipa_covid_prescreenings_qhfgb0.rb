require 'active_record/migration/app_generator'
class CreateIpaCovidPrescreeningsQhfgb0 < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'ipa_ops'
    self.table_name = 'ipa_covid_prescreenings'
    self.fields = %i[foreign_travel_yes_no covid_tested_yes_no select_test_result test_date test_location_notes covid_contact_yes_no_dont_know contact_date household_isolation_yes_no fever_yes_no tag_select_symptoms notes]
    self.table_comment = ''
    self.fields_comments = {}
    self.no_master_association = false


    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
