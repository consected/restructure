class SetupPasswordTemplates < ActiveRecord::Migration
  def change
    $dont_seed=true
    require "#{::Rails.root}/db/seeds.rb"
    Seeds::PasswordExpirationReminder.setup
  end
end
