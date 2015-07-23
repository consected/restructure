require 'support/master_support'
require Rails.root.join 'db/seeds/trackers'
module TrackerSupport
  include MasterSupport
  
  def self.create_tracker_updates        
#    TrackerSupport.create_tracker_updates
    Seeds::Trackers.setup
  end
  
  def create_tracker_updates
    admin = create_admin
#    TrackerSupport.create_tracker_updates
    Seeds::Trackers.setup
  end
  
   
end
