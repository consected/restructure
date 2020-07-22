# frozen_string_literal: true

require 'active_record/migration/app_generator'

class CreateFemflContacts < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'femfl'
    self.table_name = 'femfl_contacts'

    self.fields = %i[rec_type data rank source]

    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
