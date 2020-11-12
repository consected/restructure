# frozen_string_literal: true

require 'active_record/migration/app_generator'

class CreateExtraAppSchema < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    self.schema = 'extra_app'
    # self.owner = 'a production db user used for migrations'
    create_schema
  end
end
