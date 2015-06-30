class Tracker < ActiveRecord::Base
  include UserHandler

  belongs_to :protocol
  has_many :tracker_histories, inverse_of: :tracker
  
  def initialize presets
    
    presets[:event_date] ||= DateTime.now
    
    super
  end
  
  
  def protocol_name
    return nil unless self.protocol
    self.protocol.name
  end
  
  def tracker_history_length
    
    r = tracker_histories.length
    r
  end
  
  def as_json extras={}
    extras[:methods] ||= []
    extras[:methods] << :protocol_name
    extras[:methods] << :tracker_history_length
      
    super(extras)
  end
  
end
