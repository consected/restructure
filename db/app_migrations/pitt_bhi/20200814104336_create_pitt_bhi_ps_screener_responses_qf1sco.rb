require 'active_record/migration/app_generator'
class CreatePittBhiPsScreenerResponsesQf1sco < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'pitt_bhi'
    self.table_name = 'pitt_bhi_ps_screener_responses'
    self.fields = %i[comm_clearly_in_english_yes_no give_informed_consent_yes_no_dont_know give_informed_consent_notes outcome notes]
    self.table_comment = ''
    self.fields_comments = {}


    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
