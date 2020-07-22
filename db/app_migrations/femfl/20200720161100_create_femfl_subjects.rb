# frozen_string_literal: true

require 'active_record/migration/app_generator'

class CreateFemflSubjects < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'femfl'
    self.table_name = 'femfl_subjects'

    self.fields = %i[first_name last_name middle_name nick_name birth_date rank source]

    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
