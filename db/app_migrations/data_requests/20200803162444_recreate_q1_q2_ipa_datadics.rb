# frozen_string_literal: true

require 'active_record/migration/app_generator'
class RecreateQ1Q2IpaDatadics < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def self.up
    `bin/rails db << "set role fphs; truncate q1.q1_datadic; truncate q2.q2_datadic; truncate ipa_ops.ipa_datadic;"`
    `bin/rails db < db/app_specific/data_requests/aws-db/dictionaries/datadics.sql`
  end
end
