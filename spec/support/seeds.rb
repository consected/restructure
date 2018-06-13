# Support seeding the database
Dir[Rails.root.join('db/seeds/*.rb')].each { |f| Rails.logger.info "requiring: #{f}"; require f }

module Seeds

  def self.setup
    Rails.logger.info "============ Starting seed setup for constants (#{DateTime.now}) ==============="
    self.constants.each do |c|
      Rails.logger.info "Setup for constant #{c}"
      Seeds.const_get(c).setup
    end
    Rails.logger.info "============ Completed seed setup for constants (#{DateTime.now}) ==============="
  end

end

def auto_admin
  if defined?(@admin) && @admin
    @admin = Admin.find_by_id(@admin.id)
    return @admin if @admin
  end
  @admin, _ = ControllerMacros.create_admin
  @admin
end

def log txt
  Rails.logger.info txt
end
