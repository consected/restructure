class ProInfo < ActiveRecord::Base
  include UserHandler
  
  before_update :prevent_save
  
  attr_accessor :enable_updates
  
  protected
    def prevent_save
      return false unless @enable_updates
      return true
    end
    
    # Override to do not track this
    def track_record_update
      return true
    end
end
