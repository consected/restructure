class Tracker < ActiveRecord::Base
  include UserHandler

  belongs_to :protocol
  
  def initialize presets
    
    presets[:event_date] ||= DateTime.now
    
    super
  end
  
  
  def protocol_name
    return nil unless self.protocol
    self.protocol.name
  end
  
  def as_json extras={}
    extras[:methods] ||= []
    extras[:methods] << :protocol_name
    
    super(extras)
  end
  
end
