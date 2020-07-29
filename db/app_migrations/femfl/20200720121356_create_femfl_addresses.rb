# frozen_string_literal: true

require 'active_record/migration/app_generator'

class CreateFemflAddresses < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'femfl'
    self.table_name = 'femfl_addresses'

    self.fields = %i[
      street
      street2
      street3
      city
      state
      zip
      source
      rank
      rec_type
      country
      postal_code
      region
    ]

    create_dynamic_model_tables
    create_dynamic_model_trigger
  end
end
