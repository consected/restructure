class ProInfo < ActiveRecord::Base
  include UserHandler
  
  before_update :prevent_save
  
  # Handle special functionality and allow simple search and compound searches to function
  attr_accessor :enable_updates, :contact_data, :less_than_career_years, :more_than_career_years
  
  protected
    def prevent_save
      instance_var_init :enable_updates
      return false unless @enable_updates
      return true
    end
    
    # Override to not track this
    def track_record_update
      return true
    end
end
