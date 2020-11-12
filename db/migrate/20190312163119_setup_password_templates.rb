class SetupPasswordTemplates < ActiveRecord::Migration
  def change
    $dont_seed=true
    return unless User.respond_to?(:reset_password_sent_at=)

    begin
      require "#{::Rails.root}/db/seeds.rb"
      Seeds::PasswordExpirationReminder.setup
    rescue => e
      puts "!!!!!!!!!!! Failed to setup password expiration reminder. !!!!!!!!!!!!!!!!!"
      puts "Run rake db:seed at the end of migrations"
      puts e
      puts e.backtrace.join("\n")
    end
  end
end
