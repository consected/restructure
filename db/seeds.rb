# frozen_string_literal: true

# Reinstate this if needed to set up a new server from scratch
Dir[Rails.root.join('db/seeds/*.rb')].sort.each do |f|
  Rails.logger.info "requiring: #{f}"
  require f
end
module Seeds
  def self.setup
    Rails.logger.info "============ Starting seed setup (#{DateTime.now}) ==============="
    # puts "#{Time.now} Starting seed setup"

    do_last = []
    do_first = []
    do_mid = []

    constants.each do |c|
      s = Seeds.const_get(c)
      if s.respond_to?(:do_last) && s.do_last
        do_last << s
      elsif s.respond_to?(:do_first) && s.do_first
        do_first << s
      else
        do_mid << s
      end
    end

    do_first.each(&:setup)
    do_mid.each(&:setup)
    do_last.each(&:setup)

    Rails.logger.info "============ Completed seed setup (#{DateTime.now}) ==============="
    # puts "#{Time.now} Completed seed setup"
  end
end

def auto_admin
  # in order to potentially setup or change an admin, it is necessary to set this environment variable
  # since this is only available from command line scripts, not within the server process
  ENV['FPHS_ADMIN_SETUP'] = 'yes'
  @admin ||= Admin.find_or_create_by email: Settings::AdminEmail
  @admin.update(disabled: false) if @admin.disabled
  # puts "Admin: #{@admin.inspect}"
  @admin
end

def log(txt)
  # puts "#{Time.now} #{txt}"
  Rails.logger.info txt
end

Seeds.setup unless $dont_seed
