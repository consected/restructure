require 'active_record/migration/app_generator'
class CreateIpaPsCovidClosingsQgi47c < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'ipa_ops'
    self.table_name = 'ipa_ps_covid_closings'
    self.fields = %i[contact_later_yes_no notes]
    self.table_comment = ''
    self.fields_comments = {}


    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
