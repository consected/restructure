# Support seeding the database
Dir[Rails.root.join('db/seeds/*.rb')].each do |f|
  Rails.logger.info "requiring: #{f}"
  require f
end

module Seeds
  def self.setup
    Rails.logger.info "============ Starting seed setup for constants (#{DateTime.now}) ==============="
    constants.each do |c|
      Rails.logger.info "Setup for constant #{c}"
      Seeds.const_get(c).setup
    end
    Rails.logger.info "============ Completed seed setup for constants (#{DateTime.now}) ==============="
  end

  # Provide auto_admin as both module method and instance method
  def self.auto_admin
    @auto_admin = SetupHelper.auto_admin
    @auto_admin.disabled = false
    @auto_admin.save! if @auto_admin.changed?
    @auto_admin
  end
end

def auto_admin
  Seeds.auto_admin
end

def log(txt)
  Rails.logger.info txt
end
