class TrackerHistory < ActiveRecord::Base

  self.table_name = 'tracker_history'
  include UserHandler

  belongs_to :protocol
  has_one :tracker, inverse_of: :tracker_histories
  
  
  
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
