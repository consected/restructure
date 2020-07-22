# frozen_string_literal: true

require 'active_record/migration/app_generator'

class CreateFemflSchema < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'femfl'
    self.owner = 'fphs'
    create_schema
  end
end
