# Use this as a starting point for your task to migrate your user's OTP secrets.
namespace :devise_two_factor do
  desc 'Copy devise_two_factor OTP secret from old format to new format'
  task copy_otp_secret_to_rails7_encrypted_attr: [:environment] do
    admin = Admin.find_by email: Settings::AdminEmail.downcase

    [User, Admin].each do |klass|
      klass.find_each do |user| # find_each finds in batches of 1,000 by default
        otp_secret = user.otp_secret # read from otp_secret column, fall back to legacy columns if new column is empty
        puts "Processing #{klass.name} #{user.email} - #{user.first_name} #{user.last_name}"
        res = user.update(otp_secret: otp_secret, current_admin: admin)
        unless res
          msg = "Failed to process 2FA update for #{klass.name} #{user.email} - #{user.first_name} #{user.last_name}"
          puts msg
          Rails.logger.error msg
        end
      end
    end
  end
end
