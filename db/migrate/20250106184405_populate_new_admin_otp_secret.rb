class PopulateNewAdminOtpSecret < ActiveRecord::Migration[7.2]
  def up
    admin = Admin.find_by email: Settings::AdminEmail.downcase

    Admin.find_each do |user| # find_each finds in batches of 1,000 by default
      otp_secret = user.otp_secret # read from otp_secret column, fall back to legacy columns if new column is empty
      puts "Processing #{user.email} - #{user.first_name} #{user.last_name}"
      res = user.update(otp_secret: otp_secret, current_admin: admin)
      unless res
        msg = "Failed to process 2FA update for #{user.email} - #{user.first_name} #{user.last_name}"
        puts msg
        Rails.logger.error msg
      end
    end
  end
end
