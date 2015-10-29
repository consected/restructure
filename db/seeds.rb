# Reinstate this if needed to set up a new server from scratch
Dir[Rails.root.join('db/seeds/*.rb')].each { |f| Rails.logger.info "requiring: #{f}"; require f }
module Seeds
  
  def self.setup
    Rails.logger.info "Starting seed setup"
    
    # Reinstate this if needed to set up a new server from scratch
    self.constants.each do |c|
      Seeds.const_get(c).setup
    end
    
    
    
  end
  
end

def auto_admin 
  @admin ||= Admin.find_or_create_by email: 'auto-admin'
end

Seeds.setup
