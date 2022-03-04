class AllowUsersAccessToUserPreferences < ActiveRecord::Migration[5.2]
  def up
    $dont_seed = true

    begin
      require "#{::Rails.root}/db/seeds.rb"
      Seeds::AllowAccessToUserPreferences.setup
    rescue StandardError => e
      puts 'Run "bundle exec rails db:seed"" at the end of migrations.'
      puts e
      puts e.backtrace.join("\n")
    end
  end
end
