class RenameAndRepositionResourceFocusedUserAccessOverview < ActiveRecord::Migration[7.1]
  def up
    $dont_seed = true

    begin
      require "#{::Rails.root}/db/seeds.rb"
      Seeds::ReportUserAccessOverview.setup
    rescue StandardError => e
      puts 'Run "bundle exec rails db:seed" at the end of migrations.'
      puts e
      puts e.backtrace.join("\n")
    end
  end
end
