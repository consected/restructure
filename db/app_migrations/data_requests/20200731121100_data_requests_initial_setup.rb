# frozen_string_literal: true

require 'active_record/migration/app_generator'
class DataRequestsInitialSetup < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    `bin/rails db < db/app_specific/data_requests/aws-db/0-scripts/0-install_all.sql`
  end
end
