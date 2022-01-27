class SetupAllowUserToRegisterTemplates < ActiveRecord::Migration[5.2]
  def change
    $dont_seed=true
    return unless Settings::AllowUsersToRegister

    begin
      require "#{::Rails.root}/db/seeds.rb"
      Seeds::PasswordChangedNotification.setup
      Seeds::PasswordResetInstructionsNotification.setup
      Seeds::RegistrationConfirmation.setup
    rescue StandardError => e
      puts '!!!!!!!!!!! Failed to setup the templates required when users are allowed to register. !!!!!!!!!!!!!!!!!'
      puts 'Run rake db:seed at the end of migrations'
      puts e
      puts e.backtrace.join("\n")
    end
  end
end
