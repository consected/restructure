# Support seeding the database
Dir[Rails.root.join('db/seeds/*.rb')].each { |f| Rails.logger.info "requiring: #{f}"; require f }

module Seeds
  
  def self.setup
    Rails.logger.info "Starting seed setup"
    self.constants.each do |c|
      Seeds.const_get(c).setup
    end
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