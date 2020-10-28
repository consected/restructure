# frozen_string_literal: true

module AdminSetup
  def self.setup(admins_string)
    puts('No admin string specified in env FPHS_ADMINS') && return if admins_string.blank? && !Rails.env.test?

    admins = admins_string.split(';')
    op = ''
    success = true
    admins.each do |admin|
      admin_obj = Admin.where(email: admin).first
      if admin_obj

        admin_obj.force_password_reset
        admin_obj.disabled = false

        otpsecret = 'not changed'
        if admin_obj.respond_to?(:otp_secret) && admin_obj.otp_secret.blank? || ENV['reset_secret'] == 'yes'
          admin_obj.reset_two_factor_auth
          otpsecret = 'created'
        end

        res = admin_obj.save
        if res
          op += "Existing Admin (#{admin}) updated with new password: #{admin_obj.new_password}\n"
          op += "Two factor secret #{otpsecret}"

        else
          success = false
          op += "Existing Admin (#{admin}) failed to update. #{admin_obj.errors.inspect}\n"
        end
      else
        admin_obj = Admin.create(email: admin)
        if admin_obj
          admin_obj.reset_two_factor_auth
          otpsecret = 'created'

          op += "Admin (#{admin}) password: #{admin_obj.new_password}\n"
          op += "Two factor secret #{otpsecret}"
        else
          success = false
          op += "New Admin (#{admin}) failed to be created.\n"
        end
      end
    end

    puts op if !Rails.env.test? || ENV['SHOW_RESULT'] == 'true'

    success
  end

  def self.remove(admins_string)
    admins = admins_string.split(';')
    op = ''
    admins.each do |admin|
      admin_obj = Admin.where(email: admin).first
      if admin_obj

        # An admin is not truly removed from the database,
        # just marked as disabled
        admin_obj.disable!

        op += "Removed: #{admin}\n"
      else
        op += "Admin not recognized: #{admin}\n"
      end
    end
    puts op  unless Rails.env.test?
  end

  def self.run
    action = ENV['FPHS_ACTION']
    admins = ENV['FPHS_ADMINS']
    msg = ''

    puts "Environment: #{ENV['RAILS_ENV']}"
    puts "DB Host:     #{ENV['FPHS_POSTGRESQL_HOSTNAME']}"
    puts "Database:    #{ENV['FPHS_POSTGRESQL_DATABASE']}"

    if admins.blank? || action.blank?
      msg = <<~EOF

        Add, update or remove admin users from the FPHS app

        Usage:

        Add / update admins:
        RAILS_ENV=production FPHS_ACTION=add FPHS_ADMINS='admin1@ex.com;admin2@ex.com' rails runner app-scripts/supporting/admin_setup.rb

        Will create any specified admins not already existing with a default password
        and update any specified admins that exist, assigning them a new password

        Remove admins:

        RAILS_ENV=production FPHS_ACTION=remove FPHS_ADMINS='admin1@ex.com;admin2@ex.com' rails runner app-scripts/supporting/admin_setup.rb

        Will remove any specified admins from the admin list.

      EOF
      puts msg unless Rails.env.test?
    end

    action = ENV['FPHS_ACTION']

    if action == 'remove'
      AdminSetup.remove admins
    elsif action == 'add'
      AdminSetup.setup admins
    else
      puts "FPHS_ACTION not recognized.\n#{msg}" unless Rails.env.test?
    end
  end

  run
end
