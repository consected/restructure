# frozen_string_literal: true

# Create the message templates used to notify users when a background filestore download
# is ready, or could not be prepared (NfsStorePrepareDownloadJob)
class SetupNfsStorePreparedDownloadTemplates < ActiveRecord::Migration[7.1]
  def up
    $dont_seed = true

    begin
      require "#{::Rails.root}/db/seeds.rb"
      Seeds::NfsStorePreparedDownloadNotifications.setup
    rescue StandardError => e
      puts 'Failed to setup the prepared download notification templates.'
      puts 'Run "bundle exec rails db:seed" at the end of migrations.'
      puts e
      puts e.backtrace.join("\n")
    end
  end

  def down; end
end
