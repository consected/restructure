class TrackerHistory < ActiveRecord::Base

  self.table_name = 'tracker_history'
  include UserHandler

  belongs_to :protocol
  belongs_to :sub_process
  belongs_to :protocol_event
  has_one :tracker, inverse_of: :tracker_histories
  
  
  
  def protocol_name
    return nil unless self.protocol
    self.protocol.name
  end
  
  def sub_process_name
    return nil unless self.sub_process
    self.sub_process.name
  end
  
  def event_name
    return nil unless self.protocol_event
    self.protocol_event.name
  end
  
  def as_json extras={}
    extras[:methods] ||= []
    extras[:methods] << :protocol_name
    extras[:methods] << :sub_process_name
    extras[:methods] << :event_name
    
    super(extras)
  end
  
end
