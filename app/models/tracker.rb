class Tracker < ActiveRecord::Base
  include UserHandler

  belongs_to :protocol
  
  
  
  
  def protocol_name
    return nil unless self.protocol
    self.protocol.name
  end
  
  def as_json extras={}
    extras[:methods] ||= []
    extras[:include] ||= []
    
    extras[:methods] << :protocol_name
    extras[:include] << :item_flags
    super(extras)
  end
  
end
